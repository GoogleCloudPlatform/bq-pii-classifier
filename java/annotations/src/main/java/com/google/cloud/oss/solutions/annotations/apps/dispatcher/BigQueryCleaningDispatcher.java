/*
 *
 *  Copyright 2025 Google LLC
 *
 *  Licensed under the Apache License, Version 2.0 (the "License");
 *  you may not use this file except in compliance with the License.
 *  You may obtain a copy of the License at
 *
 *       https://www.apache.org/licenses/LICENSE-2.0
 *
 *  Unless required by applicable law or agreed to in writing, software
 *  distributed under the License is distributed on an "AS IS" BASIS,
 *  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or
 *  implied.
 *  See the License for the specific language governing permissions and
 *  limitations under the License.
 *
 */

package com.google.cloud.oss.solutions.annotations.apps.dispatcher;

import com.google.cloud.oss.solutions.annotations.entities.NonRetryableApplicationException;
import com.google.cloud.oss.solutions.annotations.helpers.TrackingHelper;
import com.google.cloud.oss.solutions.annotations.services.pubsub.BigQueryToPubSubStreamer;
import com.google.cloud.oss.solutions.annotations.services.pubsub.BigQueryToPubSubStreamerForBQCleaningDispatcher;
import java.io.IOException;
import java.util.HashMap;
import java.util.Map;
import java.util.concurrent.ExecutionException;

/**
 * Dispatcher for cleaning DLP-derived annotations from BigQuery tables. It will read DLP results from a BigQuery
 * table and publish cleaning requests to PubSub.
 */
public class BigQueryCleaningDispatcher extends BaseDispatcher {

    public BigQueryCleaningDispatcher(Environment environment) {
        super(environment);
    }

    @Override
    protected Integer getExpectedArgumentsCount() {
        return 5;
    }

    @Override
    protected String getRunId() {
        return TrackingHelper.generateCleaningRunIdForBigQuery();
    }

    @Override
    protected String getSqlTemplate() {
        return "sql/cleaner_bq.tpl";
    }

    @Override
    protected BigQueryToPubSubStreamer getBigQueryToPubSubStreamer() {
        return new BigQueryToPubSubStreamerForBQCleaningDispatcher(
                environment.getPubSubFlowControlMaxOutstandingRequestBytes(),
                environment.getPubSubFlowControlMaxOutstandingElementCount(),
                environment.getPubSubBatchingElementCountThreshold(),
                environment.getPubSubBatchingRequestByteThreshold(),
                environment.getPubSubBatchingDelayThresholdMillis(),
                environment.getPubSubRetryInitialRetryDelayMillis(),
                environment.getPubSubRetryRetryDelayMultiplier(),
                environment.getPubSubRetryMaxRetryDelaySeconds(),
                environment.getPubSubRetryInitialRpcTimeoutSeconds(),
                environment.getPubSubRetryRpcTimeoutMultiplier(),
                environment.getPubSubRetryMaxRpcTimeoutSeconds(),
                environment.getPubSubRetryTotalTimeoutSeconds(),
                environment.getPubSubExecutorThreadCountMultiplier());
    }

    @Override
    protected Map<String, String> getTemplateParams(String[] args) {

        String foldersRegex = args[0];
        String projectsRegex = args[1];
        String datasetsRegex = args[2];
        String tablesRegex = args[3];
        String rowsMultiplicationFactor = args[4];

        Map<String, String> map = new HashMap<>();

        map.put("${project}", this.environment.getPublishingProjectId());
        map.put("${dlp_dataset}", this.environment.getDlpResultsDataset());
        map.put("${logging_dataset}", this.environment.getLoggingDataset());
        map.put("${results_table}", this.environment.getDlpResultsTable());
        map.put("${dispatcher_runs_table}", this.environment.getDispatcherRunsTable());
        map.put("${folder_id_regex}", foldersRegex);
        map.put("${project_id_regex}", projectsRegex);
        map.put("${dataset_id_regex}", datasetsRegex);
        map.put("${table_id_regex}", tablesRegex);
        map.put("${rows_multiplication_factor}", rowsMultiplicationFactor);
        map.put("${run_id}", this.runId);
        map.put("${dlp_sensitivity_level_tag_value_high}", environment.getDlpTagValueHigh());
        map.put("${dlp_sensitivity_level_tag_value_moderate}", environment.getDlpTagValueModerate());
        map.put("${dlp_sensitivity_level_tag_value_low}", environment.getDlpTagValueLow());

        return map;
    }

    public static void main(String[] args)
            throws NonRetryableApplicationException,
            IOException,
            ExecutionException,
            InterruptedException {
        new BigQueryCleaningDispatcher(new Environment()).run(args);
    }
}
