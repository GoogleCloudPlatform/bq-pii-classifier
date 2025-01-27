/*
 * Copyright 2025 Google LLC
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

package com.google.cloud.pso.bq_pii_classifier.functions.tagger.gcs;

import com.google.api.services.bigquery.model.TableFieldSchema;
import com.google.api.services.bigquery.model.TableFieldSchema.PolicyTags;
import com.google.cloud.pso.bq_pii_classifier.entities.*;
import com.google.cloud.pso.bq_pii_classifier.functions.tagger.ColumnTaggingAction;
import com.google.cloud.pso.bq_pii_classifier.functions.tagger.TaggerConfig;
import com.google.cloud.pso.bq_pii_classifier.helpers.LoggingHelper;
import com.google.cloud.pso.bq_pii_classifier.helpers.Utils;
import com.google.cloud.pso.bq_pii_classifier.services.findings.GcsFindingsReader;
import com.google.cloud.pso.bq_pii_classifier.services.gcs.GcsService;
import com.google.cloud.pso.bq_pii_classifier.services.set.PersistentSet;
import org.slf4j.event.Level;

import java.io.IOException;
import java.util.*;
import java.util.stream.Collectors;

public class GcsTagger {

    private final LoggingHelper logger;

    private static final Integer functionNumber = 3;
    private TaggerConfig config;

    private GcsFindingsReader findingsReader;

    private GcsService gcsService;
    private PersistentSet persistentSet;
    private String persistentSetObjectPrefix;

    public GcsTagger(TaggerConfig config,
                     GcsFindingsReader findingsReader,
                     GcsService gcsService,
                     PersistentSet persistentSet,
                     String persistentSetObjectPrefix
    ) throws IOException {

        this.config = config;
        this.findingsReader = findingsReader;
        this.gcsService = gcsService;
        this.persistentSet = persistentSet;
        this.persistentSetObjectPrefix = persistentSetObjectPrefix;

        logger = new LoggingHelper(
                GcsTagger.class.getSimpleName(),
                functionNumber,
                config.getProjectId()
        );
    }

    /**
     * @param request The request object for the tagging operation.
     * @param pubSubMessageId The pubsub message id containing the request. This is used to ensure exactly once processing
     * @return A map of detected InfoTypes names and the metadata configured for each one of them .
     */
    public Map<String, InfoTypeInfo> execute(
            GcsTaggerRequest request,
            String pubSubMessageId
    ) throws NonRetryableApplicationException, IOException {

        logger.logFunctionStart(request.getTrackingId());
        logger.logInfoWithTracker(request.getTrackingId(),
                String.format("Request : %s", request.toString()));

        /**
         *  Check if we already processed this pubSubMessageId before to avoid submitting BQ queries
         *  in case we have unexpected errors with PubSub re-sending the message. This is an extra measure to avoid unnecessary cost.
         *  We do that by keeping simple flag files in GCS with the pubSubMessageId as file name.
         */
        String flagFileName = String.format("%s/%s", persistentSetObjectPrefix, pubSubMessageId);
        if (persistentSet.contains(flagFileName)) {
            // log error and ACK and return
            String msg = String.format("PubSub message ID '%s' has been processed before by the Tagger. The message should be ACK to PubSub to stop retries. Please investigate further why the message was retried in the first place.",
                    pubSubMessageId);
            throw new NonRetryableApplicationException(msg);
        }

        Set<String> detectedInfoTypes = findingsReader.getFileStoreDataProfileDetectedInfoTypes(request.getFileStoreProfileName());

        Map<String, InfoTypeInfo> detectedInfoTypesWithMetadata = filterInfoTypesMetadataMap(detectedInfoTypes,
                config.getInfoTypeMap());

        // construct a map of label key, label value based on all labels configured for all detected info types
        Map<String, String> bucketLabels = generateBucketLabelsFromDlpFindings(detectedInfoTypes,
                detectedInfoTypesWithMetadata);

        //log found labels for this bucket
        for (Map.Entry<String, String> labelEntry : bucketLabels.entrySet()) {
            logger.logBucketLabelsHistory(request.getBucketName(),
                    labelEntry.getKey(),
                    labelEntry.getValue(),
                    config.isDryRunLabels(),
                    request.getTrackingId());
        }

        // attach labels to GCS bucket based on the isDryRunLabels()
        if(!config.isDryRunLabels() && bucketLabels.size() > 0){
            gcsService.addLabelsToBucket(request.getBucketName(), bucketLabels);

            logger.logInfoWithTracker(request.getTrackingId(),
                    String.format("Added %s labels to bucket %s .", bucketLabels.size(), request.getBucketPath())
            );
        }

        // Add a flag key marking that we already completed this request and no additional runs
        // are required in case PubSub is in a loop of retrying due to ACK timeout while the service has already processed the request
        // This is an extra measure to avoid unnecessary cost due to config issues.
        logger.logInfoWithTracker(request.getTrackingId(), String.format("Persisting processing key for PubSub message ID %s", pubSubMessageId));
        persistentSet.add(flagFileName);

        logger.logFunctionEnd(request.getTrackingId());

        return detectedInfoTypesWithMetadata;
    }


    /**
     *
     * @param infoTypes A list of info types names
     * @param infoTypeMetadataMap A Map<info type name, info type metadata>
     * @return A subset of map infoTypeMetadataMap with only the info type entries/keys that are found in infoTypes
     */
    public static Map<String, InfoTypeInfo> filterInfoTypesMetadataMap(Set<String> infoTypes,
            Map<String, InfoTypeInfo> infoTypeMetadataMap) {

        return infoTypeMetadataMap.entrySet().stream()
                .filter(entry -> infoTypes.contains(entry.getKey()))
                .collect(Collectors.toMap(Map.Entry::getKey, Map.Entry::getValue));
    }

    /**
     *
     * @param infoTypesFindings A list of info types names that are detected by DLP in a bucket
     * @param infoTypeMetadataMap A Map<info type name, info type metadata> used as master data for lookup
     * @return A map of label key, label value pairs that are configured for all info types in the infoTypesFindings list
     */
    public static Map<String, String> generateBucketLabelsFromDlpFindings(Set<String> infoTypesFindings,
                                                                          Map<String, InfoTypeInfo> infoTypeMetadataMap) {
        Map<String, String> bucketLabels = new HashMap<>();
        // loop on all InfoTyps found in that bucket
        for (String infoType : infoTypesFindings) {
            // lookup the labels associated with that info type based on the classification taxonomy (in Terraform)
            // add each label to the map. Duplicate labels across InfoTypes will be overwritten.
            for (ResourceLabel infoTypeLabel : infoTypeMetadataMap.get(infoType).getLabels()) {
                bucketLabels.put(infoTypeLabel.getKey().toLowerCase(), infoTypeLabel.getValue().toLowerCase());
            }
        }
        return bucketLabels;
    }
}