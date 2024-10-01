/*
 * Copyright 2022 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     https://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

package com.google.cloud.pso.bq_pii_classifier.functions.dispatcher;

import com.google.cloud.pso.bq_pii_classifier.entities.*;
import com.google.cloud.pso.bq_pii_classifier.functions.inspector.InspectorRequest;
import com.google.cloud.pso.bq_pii_classifier.functions.tagger.TaggerDlpJobRequest;
import com.google.cloud.pso.bq_pii_classifier.functions.tagger.TaggerTableSpecRequest;
import com.google.cloud.pso.bq_pii_classifier.helpers.LoggingHelper;
import com.google.cloud.pso.bq_pii_classifier.helpers.TrackingHelper;
import com.google.cloud.pso.bq_pii_classifier.helpers.Utils;
import com.google.cloud.pso.bq_pii_classifier.services.bq.BigQueryService;
import com.google.cloud.pso.bq_pii_classifier.services.pubsub.FailedPubSubMessage;
import com.google.cloud.pso.bq_pii_classifier.services.pubsub.PubSubPublishResults;
import com.google.cloud.pso.bq_pii_classifier.services.pubsub.PubSubService;
import com.google.cloud.pso.bq_pii_classifier.services.pubsub.SuccessPubSubMessage;
import com.google.cloud.pso.bq_pii_classifier.services.set.PersistentSet;
import com.google.cloud.pso.bq_pii_classifier.services.scan.*;


import java.io.IOException;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.Set;


public class Dispatcher {

    private static final Integer functionNumber = 1;

    private final LoggingHelper logger;
    private BigQueryService bqService;
    private PubSubService pubSubService;
    private Scanner scanner;
    private DispatcherConfig config;
    private PersistentSet persistentSet;
    private String persistentSetObjectPrefix;
    private String runId;

    public Dispatcher(DispatcherConfig config,
                      BigQueryService bqService,
                      PubSubService pubSubService,
                      Scanner scanner,
                      PersistentSet persistentSet,
                      String persistentSetObjectPrefix,
                      String runId) {

        this.config = config;
        this.bqService = bqService;
        this.pubSubService = pubSubService;
        this.scanner = scanner;
        this.persistentSet = persistentSet;
        this.persistentSetObjectPrefix = persistentSetObjectPrefix;
        this.runId = runId;

        logger = new LoggingHelper(
                Dispatcher.class.getSimpleName(),
                functionNumber,
                config.getProjectId()
        );
    }

    public PubSubPublishResults execute(BigQueryScope bqScope, String pubSubMessageId) throws IOException, NonRetryableApplicationException, InterruptedException {

        /**
         *  Check if we already processed this pubSubMessageId before to avoid re-running the dispatcher (and the whole process)
         *  in case we have unexpected errors with PubSub re-sending the message. This is an extra measure to avoid unnecessary cost.
         *  We do that by keeping simple flag files in GCS with the pubSubMessageId as file name.
         */
        String flagFileName = String.format("%s/%s", persistentSetObjectPrefix, pubSubMessageId);
        if (persistentSet.contains(flagFileName)) {
            // log error and ACK and return
            String msg = String.format("PubSub message ID '%s' has been processed before by the dispatcher. The message should be ACK to PubSub to stop retries. Please investigate further why the message was retried in the first place.",
                    pubSubMessageId);
            throw new NonRetryableApplicationException(msg);
        } else {
            logger.logInfoWithTracker(runId, String.format("Persisting processing key for PubSub message ID %s", pubSubMessageId));
            persistentSet.add(flagFileName);
        }

        /**
         * Detecting which resources to tag is done bottom up DATASETS > PROJECTS where lower levels configs (e.g. dataset)
         * ignore higher level configs (e.g. Datasets)
         * For example:
         * If DATASETS_INCLUDE list is provided:
         *  * Tag only tables in these datasets
         *  * SKIP datasets in DATASETS_EXCLUDE
         *  * SKIP tables in TABLES_EXCLUDE
         *  * IGNORE all other INCLUDE lists
         * If PROJECTS_INCLUDE list is provided:
         *  * Tag only datasets and tables in these projects
         *  * SKIP datasets in DATASETS_EXCLUDE
         *  * SKIP tables in TABLES_EXCLUDE
         *  * IGNORE all other INCLUDE lists
         */

        // List down which tables to publish a Tagging request for based on the input scan scope and DLP results table

        List<JsonMessage> pubSubMessagesToPublish;

        if (!bqScope.getDatasetIncludeList().isEmpty()) {
            pubSubMessagesToPublish = processDatasets(
                    bqScope.getDatasetIncludeList(),
                    bqScope.getDatasetExcludeList(),
                    bqScope.getTableExcludeList());
        } else {
            if (!bqScope.getProjectIncludeList().isEmpty()) {
                pubSubMessagesToPublish = processProjects(
                        bqScope.getProjectIncludeList(),
                        bqScope.getDatasetExcludeList(),
                        bqScope.getTableExcludeList());
            } else {
                throw new NonRetryableApplicationException("At least one of of the following params must be not empty [tableIncludeList, datasetIncludeList, projectIncludeList]");
            }
        }

        // Publish the list of tagging requests to PubSub
        PubSubPublishResults publishResults = pubSubService.publishTableOperationRequests(
                config.getProjectId(),
                config.getOutputTopic(),
                pubSubMessagesToPublish
        );

        for (FailedPubSubMessage msg : publishResults.getFailedMessages()) {
            String logMsg = String.format("Failed to publish this messages %s", msg.toString());
            logger.logWarnWithTracker(runId, logMsg);
        }

        for (SuccessPubSubMessage msg : publishResults.getSuccessMessages()) {
            // this enable us to detect dispatched messages within a runId that fail in later stages (i.e. Tagger)

            // Log the dispatched tracking ID to be able to track the progress of this run
            if (config.getSolutionMode().equals(SolutionMode.STANDARD_DLP) && config.getDispatcherType().equals(DispatcherType.INSPECTION)) {
                InspectorRequest request = ((InspectorRequest) msg.getMsg());
                logger.logSuccessDispatcherTrackingId(runId, request.getTrackingId(), request.getTargetTable());
            } else {
                if (config.getSolutionMode().equals(SolutionMode.AUTO_DLP)) {
                    TaggerTableSpecRequest request = ((TaggerTableSpecRequest) msg.getMsg());
                    logger.logSuccessDispatcherTrackingId(runId, request.getTrackingId(), request.getTargetTable());
                } else {
                    if (config.getSolutionMode().equals(SolutionMode.STANDARD_DLP) && config.getDispatcherType().equals(DispatcherType.TAGGING)) {
                        TaggerDlpJobRequest request = ((TaggerDlpJobRequest) msg.getMsg());
                        logger.logSuccessDispatcherTrackingId(runId, request.getTrackingId());
                    }
                }
            }
        }

        logger.logFunctionEnd(runId);

        return publishResults;
    }

    public List<JsonMessage> processTables(List<String> tableIncludeList,
                                           List<String> tableExcludeList,
                                           List<String> inspectionTemplatesIds,
                                           String dlpJobRegion
    ) {
        List<JsonMessage> pubSubMessagesToPublish = new ArrayList<>();

        // entity is a table spec string p.d.t in case of Standard Mode Inspection Dispatcher and sent to the Inspector Service
        // entity is a table spec string p.d.t in case of Auto DLP mode Tagging Dispatcher and sent to the Tagger Service
        // entity is a dlpJobName in case of Standard Mode Tagging Dispatcher and sent to the Tagger Service
        for (String entity : tableIncludeList) {
            try {
                if (!tableExcludeList.contains(entity)) {

                    String trackingId = TrackingHelper.generateTrackingId(runId, entity);

                    if (config.getSolutionMode().equals(SolutionMode.STANDARD_DLP) && config.getDispatcherType().equals(DispatcherType.INSPECTION)) {

                        for (int i = 0; i < inspectionTemplatesIds.size(); i++) {
                            // submit n inspection requests depending on the number of inspection templates in one region
                            InspectorRequest operation = new InspectorRequest(
                                    runId,
                                    String.format("%s_%s", trackingId, (i + 1)), // use tabletrackingid_inspectiontemplatenumber to diff between requests and paths
                                    TableSpec.fromSqlString(entity),
                                    inspectionTemplatesIds.get(i),
                                    dlpJobRegion); // run the dlp job in the same region as the source table to avoid network cost
                            pubSubMessagesToPublish.add(operation);
                        }

                    } else {
                        if (config.getSolutionMode().equals(SolutionMode.AUTO_DLP)) {
                            TaggerTableSpecRequest operation = new TaggerTableSpecRequest(runId, trackingId, TableSpec.fromSqlString(entity));
                            pubSubMessagesToPublish.add(operation);
                        } else {
                            if (config.getSolutionMode().equals(SolutionMode.STANDARD_DLP) && config.getDispatcherType().equals(DispatcherType.TAGGING)) {
                                TaggerDlpJobRequest operation = new TaggerDlpJobRequest(runId, trackingId, entity);
                                pubSubMessagesToPublish.add(operation);
                            } else {
                                throw new NonRetryableApplicationException(String.format("Solution Mode %s and Dispatcher Type %s are not supported in the Dispatcher logic",
                                        config.getSolutionMode(), config.getDispatcherType()));
                            }
                        }
                    }
                }
            } catch (Exception ex) {
                // log and continue
                logger.logFailedDispatcherEntityId(runId, entity, ex);
            }
        }
        return pubSubMessagesToPublish;
    }

    public List<JsonMessage> processDatasets(List<String> datasetIncludeList,
                                             List<String> datasetExcludeList,
                                             List<String> tableExcludeList
    ){
        List<JsonMessage> allJsonMessages = new ArrayList<>();

        for (String dataset : datasetIncludeList) {
            String datasetLocation = "";
            try {

                if (!datasetExcludeList.contains(dataset)) {

                    List<String> tokens = Utils.tokenize(dataset, ".", true);
                    String projectId = tokens.get(0);
                    String datasetId = tokens.get(1);

                    datasetLocation = bqService.getDatasetLocation(projectId, datasetId).toLowerCase();
                    if (!config.getSourceDataRegions().contains(datasetLocation)) {
                        logger.logWarnWithTracker(runId,
                                String.format(
                                        "Ignoring dataset %s in region '%s'. Only regions '%s' are configured.",
                                        dataset,
                                        datasetLocation,
                                        config.getSourceDataRegions())
                        );
                        continue;
                    }

                    // get the inspection template to be use in the region of this dataset
                    if (!config.getDlpInspectionTemplatesIdsPerRegion().keySet().contains(datasetLocation)) {
                        String msg = String.format(
                                "No DLP inspection template(s) found for source data region '%s'",
                                datasetLocation);
                        throw new NonRetryableApplicationException(msg);
                    }
                    List<String> inspectionTemplatesIds = config.getDlpInspectionTemplatesIdsPerRegion().get(datasetLocation);

                    // get all tables that have DLP findings
                    List<String> tablesIncludeList = scanner.listChildren(projectId, datasetId);

                    if (tablesIncludeList.isEmpty()) {
                        String msg = String.format(
                                "No Tables found under dataset '%s'",
                                dataset);

                        logger.logWarnWithTracker(runId, msg);
                    } else {
                        logger.logInfoWithTracker(runId, String.format("Tables found in dataset %s : %s", dataset, tablesIncludeList));

                        // accumulate all messages to be omitted after the loop
                        List<JsonMessage> jsonMessages = processTables(tablesIncludeList,
                                tableExcludeList,
                                inspectionTemplatesIds,
                                datasetLocation.equals("eu")? "europe": datasetLocation);

                        allJsonMessages.addAll(jsonMessages);
                    }
                }
            } catch (Exception exception) {
                // log and continue
                logger.logFailedDispatcherEntityId(runId, dataset, exception);
            }
        }
        return allJsonMessages;
    }


    public List<JsonMessage> processProjects(
            List<String> projectIncludeList,
            List<String> datasetExcludeList,
            List<String> tableExcludeList
    ) throws IOException, InterruptedException, NonRetryableApplicationException {

        List<String> datasetIncludeList = new ArrayList<>();

        logger.logInfoWithTracker(runId, String.format("Will process projects %s", projectIncludeList));

        for (String project : projectIncludeList) {
            logger.logInfoWithTracker(runId, String.format("Inspecting project %s", project));

            try {

                // get all datasets with tables that have DLP findings
                List<String> projectDatasets = scanner.listParents(project);
                datasetIncludeList.addAll(projectDatasets);

                if (projectDatasets.isEmpty()) {
                    String msg = String.format(
                            "No datasets found under project '%s'.",
                            project);

                    logger.logWarnWithTracker(runId, msg);
                } else {

                    logger.logInfoWithTracker(runId, String.format("Datasets found in project %s : %s", project, projectDatasets));
                }

            } catch (Exception exception) {
                // log and continue
                logger.logFailedDispatcherEntityId(runId, project, exception);
            }

        }
        return processDatasets(datasetIncludeList, datasetExcludeList, tableExcludeList);
    }

}
