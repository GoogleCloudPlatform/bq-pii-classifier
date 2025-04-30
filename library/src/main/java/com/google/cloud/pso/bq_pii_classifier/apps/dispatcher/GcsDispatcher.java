package com.google.cloud.pso.bq_pii_classifier.apps.dispatcher;

import com.google.cloud.pso.bq_pii_classifier.entities.NonRetryableApplicationException;
import com.google.cloud.pso.bq_pii_classifier.helpers.TrackingHelper;
import com.google.cloud.pso.bq_pii_classifier.services.pubsub.BigQueryToPubSubStreamer;
import com.google.cloud.pso.bq_pii_classifier.services.pubsub.BigQueryToPubSubStreamerForGcsDispatcher;
import java.io.IOException;
import java.util.Map;
import java.util.concurrent.ExecutionException;

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
