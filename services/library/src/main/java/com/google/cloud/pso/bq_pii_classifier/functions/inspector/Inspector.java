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

package com.google.cloud.pso.bq_pii_classifier.functions.inspector;


import com.google.cloud.pso.bq_pii_classifier.entities.NonRetryableApplicationException;
import com.google.cloud.pso.bq_pii_classifier.entities.Operation;
import com.google.cloud.pso.bq_pii_classifier.entities.TableScanLimitsConfig;
import com.google.cloud.pso.bq_pii_classifier.entities.TableSpec;
import com.google.cloud.pso.bq_pii_classifier.helpers.LoggingHelper;
import com.google.cloud.pso.bq_pii_classifier.services.BigQueryService;
import com.google.cloud.pso.bq_pii_classifier.services.DlpService;
import com.google.cloud.pso.bq_pii_classifier.services.PersistentSet;
import com.google.privacy.dlp.v2.Action;
import com.google.privacy.dlp.v2.BigQueryOptions;
import com.google.privacy.dlp.v2.BigQueryTable;
import com.google.privacy.dlp.v2.CreateDlpJobRequest;
import com.google.privacy.dlp.v2.DlpJob;
import com.google.privacy.dlp.v2.InspectConfig;
import com.google.privacy.dlp.v2.InspectJobConfig;
import com.google.privacy.dlp.v2.Likelihood;
import com.google.privacy.dlp.v2.LocationName;
import com.google.privacy.dlp.v2.OutputStorageConfig;
import com.google.privacy.dlp.v2.StorageConfig;

import java.io.IOException;

public class Inspector {

    private final LoggingHelper logger;

    private static final Integer functionNumber = 2;

    private InspectorConfig config;
    private DlpService dlpService;
    private BigQueryService bqService;
    private PersistentSet persistentSet;
    private String persistentSetObjectPrefix;


    public Inspector(InspectorConfig config,
                     DlpService dlpService,
                     BigQueryService bqService,
                     PersistentSet persistentSet,
                     String persistentSetObjectPrefix
                     ){
        this.config = config;
        this.dlpService = dlpService;
        this.bqService = bqService;
        this.persistentSet = persistentSet;
        this.persistentSetObjectPrefix = persistentSetObjectPrefix;

        logger = new LoggingHelper(
                Inspector.class.getSimpleName(),
                functionNumber,
                config.getProjectId()
        );
    }

    public DlpJob execute(Operation request, String trackingId, String pubSubMessageId) throws IOException, NonRetryableApplicationException {

        logger.logFunctionStart(trackingId);
        logger.logInfoWithTracker(trackingId, String.format("Request : %s", request.toString()));

        /**
         *  Check if we already processed this pubSubMessageId before to avoid submitting BQ queries
         *  in case we have unexpected errors with PubSub re-sending the message. This is an extra measure to avoid unnecessary cost.
         *  We do that by keeping simple flag files in GCS with the pubSubMessageId as file name.
         */
        String flagFileName = String.format("%s/%s", persistentSetObjectPrefix, pubSubMessageId);
        if(persistentSet.contains(flagFileName)){
            // log error and ACK and return
            String msg = String.format("PubSub message ID '%s' has been processed before by %s. The message should be ACK to PubSub to stop retries. Please investigate further why the message was retried in the first place.",
                    pubSubMessageId,
                    this.getClass().getSimpleName()
                    );
            throw new NonRetryableApplicationException(msg);
        }

        // get Table Scan Limits config and Table size
        TableScanLimitsConfig tableScanLimitsConfig  = new TableScanLimitsConfig(
                config.getTableScanLimitsJsonConfig());

        logger.logInfoWithTracker(trackingId,
                String.format("TableScanLimitsConfig is %s", tableScanLimitsConfig.toString()));

        // DLP job config accepts Integer only for table scan limit. Must downcast
        // NumRows from BigInteger to Integer
        TableSpec targetTableSpec = TableSpec.fromSqlString(request.getEntityKey());

        Integer tableNumRows = bqService.getTableNumRows(targetTableSpec).intValue();

        InspectJobConfig jobConfig = createJob(
                targetTableSpec,
                tableScanLimitsConfig,
                tableNumRows,
                config
        );

        CreateDlpJobRequest createDlpJobRequest = CreateDlpJobRequest.newBuilder()
                .setJobId(trackingId) // Letters, numbers, hyphens, and underscores allowed.
                .setParent(LocationName.of(config.getProjectId(), config.getRegionId()).toString())
                .setInspectJob(jobConfig)
                .build();

        DlpJob submittedDlpJob = dlpService.submitJob(createDlpJobRequest);

        logger.logInfoWithTracker(trackingId, String.format("DLP job created successfully id='%s'",
                submittedDlpJob.getName()));

        // Add a flag key marking that we already completed this request and no additional runs
        // are required in case PubSub is in a loop of retrying due to ACK timeout while the service has already processed the request
        // This is an extra measure to avoid unnecessary cost due to config issues.
        logger.logInfoWithTracker(trackingId, String.format("Persisting processing key for PubSub message ID %s", pubSubMessageId));
        persistentSet.add(flagFileName);

        logger.logFunctionEnd(trackingId);

        return submittedDlpJob;
    }

    private InspectJobConfig createJob(
            TableSpec targetTableSpec,
            TableScanLimitsConfig rowsLimitConfig,
            Integer tableNumRows,
            InspectorConfig config){

        // 1. Specify which table to inspect

        BigQueryTable bqTable = BigQueryTable.newBuilder()
                .setProjectId(targetTableSpec.getProject())
                .setDatasetId(targetTableSpec.getDataset())
                .setTableId(targetTableSpec.getTable())
                .build();

        BigQueryOptions.Builder bqOptionsBuilder = BigQueryOptions.newBuilder()
                .setTableReference(bqTable)
                .setSampleMethod(BigQueryOptions.SampleMethod.forNumber(config.getSamplingMethod()));

        Integer limitValue =  rowsLimitConfig.getTableScanLimitBasedOnNumRows(tableNumRows);

        switch (rowsLimitConfig.getScanLimitsType()){
            case NUMBER_OF_ROWS:  bqOptionsBuilder.setRowsLimit(limitValue); break;
            case PERCENTAGE_OF_ROWS: bqOptionsBuilder.setRowsLimitPercent(limitValue); break;
        }

        BigQueryOptions bqOptions = bqOptionsBuilder.build();

        StorageConfig storageConfig =
                StorageConfig.newBuilder()
                        .setBigQueryOptions(bqOptions)
                        .build();

        // The minimum likelihood required before returning a match:
        // See: https://cloud.google.com/dlp/docs/likelihood
        Likelihood minLikelihood = Likelihood.valueOf(config.getMinLikelihood());

        // The maximum number of findings to report (0 = server maximum)
        InspectConfig.FindingLimits findingLimits =
                InspectConfig.FindingLimits.newBuilder()
                        .setMaxFindingsPerItem(config.getMaxFindings())
                        .build();

        InspectConfig inspectConfig =
                InspectConfig.newBuilder()
                        .setIncludeQuote(false) // don't store identified PII in the table
                        .setMinLikelihood(minLikelihood)
                        .setLimits(findingLimits)
                        .build();

        // 2. Specify saving detailed results to BigQuery.

        // Save detailed findings to BigQuery
        BigQueryTable outputBqTable = BigQueryTable.newBuilder()
                .setProjectId(config.getProjectId())
                .setDatasetId(config.getBqResultsDataset())
                .setTableId(config.getBqResultsTable())
                .build();
        OutputStorageConfig outputStorageConfig = OutputStorageConfig.newBuilder()
                .setTable(outputBqTable)
                .build();
        Action.SaveFindings saveFindingsActions = Action.SaveFindings.newBuilder()
                .setOutputConfig(outputStorageConfig)
                .build();
        Action bqAction = Action.newBuilder()
                .setSaveFindings(saveFindingsActions)
                .build();

        // 3. Specify sending PubSub notification on completion.
        Action.PublishToPubSub publishToPubSub = Action.PublishToPubSub.newBuilder()
                .setTopic(config.getDlpNotificationTopic())
                .build();
        Action pubSubAction = Action.newBuilder()
                .setPubSub(publishToPubSub)
                .build();

        // Configure the inspection job we want the service to perform.
        return InspectJobConfig.newBuilder()
                .setInspectTemplateName(config.getDlpInspectionTemplateId())
                .setInspectConfig(inspectConfig)
                .setStorageConfig(storageConfig)
                .addActions(bqAction)
                .addActions(pubSubAction)
                .build();
    }


}
