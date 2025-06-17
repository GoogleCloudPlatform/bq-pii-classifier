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
import com.google.cloud.oss.solutions.annotations.services.pubsub.BigQueryToPubSubStreamerForGcsDispatcher;
import java.io.IOException;
import java.util.Map;
import java.util.concurrent.ExecutionException;

/**
 * Dispatcher for DLP Discovery Service Results for GCS. It will read DLP results from a BigQuery
 * table and publish to PubSub.
 */
public class GcsDispatcher extends BaseDispatcher {

  public GcsDispatcher(Environment environment) {
    super(environment);
  }

  @Override
  protected Integer getExpectedArgumentsCount() {
    return 4;
  }

  @Override
  protected String getRunId() {
    return TrackingHelper.generateTaggingRunIdForGcs();
  }

  @Override
  protected String getSqlTemplate() {
    return "sql/dispatcher_gcs.tpl";
  }

  @Override
  protected BigQueryToPubSubStreamer getBigQueryToPubSubStreamer() {
    return new BigQueryToPubSubStreamerForGcsDispatcher(
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
    String bucketsRegex = args[2];
    String rowsMultiplicationFactor = args[3];

    return Map.of(
        "${project}",
        this.environment.getPublishingProjectId(),
        "${dlp_dataset}",
        this.environment.getDlpResultsDataset(),
        "${logging_dataset}",
        this.environment.getLoggingDataset(),
        "${dlp_gcs_results_table}",
        this.environment.getDlpResultsTable(),
        "${dispatcher_runs_table}",
        this.environment.getDispatcherRunsTable(),
        "${project_name_regex}",
        projectsRegex,
        "${bucket_name_regex}",
        bucketsRegex,
        "${folder_id_regex}",
        foldersRegex,
        "${rows_multiplication_factor}",
        rowsMultiplicationFactor,
        "${run_id}",
        this.runId);
  }

  public static void main(String[] args)
      throws NonRetryableApplicationException,
          IOException,
          ExecutionException,
          InterruptedException {
    new GcsDispatcher(new Environment()).run(args);
  }
}
