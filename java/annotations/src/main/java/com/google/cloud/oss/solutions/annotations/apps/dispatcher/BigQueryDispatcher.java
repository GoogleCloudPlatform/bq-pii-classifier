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
import com.google.cloud.oss.solutions.annotations.services.pubsub.BigQueryToPubSubStreamerForBQDispatcher;
import java.io.IOException;
import java.util.Map;
import java.util.concurrent.ExecutionException;

/**
 * Dispatcher for DLP Discovery Service Results for BigQuery . It will read DLP results from a
 * BigQuery table and publish to PubSub.
 */
public class BigQueryDispatcher extends BaseDispatcher {

  public BigQueryDispatcher(Environment environment) {
    super(environment);
  }

  @Override
  protected Integer getExpectedArgumentsCount() {
    return 4;
  }

  @Override
  protected String getRunId() {
    return TrackingHelper.generateTaggingRunIdForBigQuery();
  }

  @Override
  protected String getSqlTemplate() {
    return "sql/dispatcher_bq.tpl";
  }

  @Override
  protected BigQueryToPubSubStreamer getBigQueryToPubSubStreamer() {
    return new BigQueryToPubSubStreamerForBQDispatcher(
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

    return Map.of(
        "${project}",
        this.environment.getPublishingProjectId(),
        "${dlp_dataset}",
        this.environment.getDlpResultsDataset(),
        "${logging_dataset}",
        this.environment.getLoggingDataset(),
        "${results_table}",
        this.environment.getDlpResultsTable(),
        "${folder_id_regex}",
        foldersRegex,
        "${project_id_regex}",
        projectsRegex,
        "${dataset_id_regex}",
        datasetsRegex,
        "${table_id_regex}",
        tablesRegex,
        "${dispatcher_runs_table}",
        this.environment.getDispatcherRunsTable(),
        "${run_id}",
        this.runId);
  }

  public static void main(String[] args)
      throws NonRetryableApplicationException,
          IOException,
          ExecutionException,
          InterruptedException {
    new BigQueryDispatcher(new Environment()).run(args);
  }
}
