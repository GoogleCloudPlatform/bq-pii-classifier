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

package com.google.cloud.oss.solutions.annotations.helpers;

import static net.logstash.logback.argument.StructuredArguments.kv;

import com.google.cloud.oss.solutions.annotations.entities.ApplicationLog;
import com.google.cloud.oss.solutions.annotations.entities.FunctionLifeCycleEvent;
import com.google.cloud.oss.solutions.annotations.entities.ResourceLabelingAction;
import com.google.cloud.oss.solutions.annotations.entities.TableSpec;
import com.google.cloud.oss.solutions.annotations.entities.TagHistoryLogEntry;
import java.util.Arrays;
import java.util.stream.Stream;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.slf4j.event.Level;

/**
 * Helper class for logging with structured data.
 *
 * <p>This class provides methods to log messages with different severity levels, and includes
 * structured data in the logs to facilitate querying and analysis. It uses SLF4J for logging and
 * Logstash for structured data encoding.
 */
public class LoggingHelper {

  /** Logger to be used by the class */
  private final Logger logger;

  private final String loggerName;
  private final Integer functionNumber;
  // Used to create a trace
  private final String projectId;

  private final String applicationName;

  public LoggingHelper(String loggerName, Integer functionNumber, String projectId) {
    this.loggerName = loggerName;
    this.functionNumber = functionNumber;
    this.projectId = projectId;
    this.applicationName = "bq-pii-classifier";

    logger = LoggerFactory.getLogger(loggerName);
  }

  public void logDebugWithTracker(String tracker, String entityId, String msg) {
    logWithTracker(ApplicationLog.DEFAULT_LOG, tracker, entityId, msg, Level.DEBUG);
  }

  public void logInfoWithTracker(String tracker, String entityId, String msg) {
    logWithTracker(ApplicationLog.DEFAULT_LOG, tracker, entityId, msg, Level.INFO);
  }

  public void logWarnWithTracker(String tracker, String entityId, String msg) {
    logWithTracker(ApplicationLog.DEFAULT_LOG, tracker, entityId, msg, Level.WARN);
  }

  public void logSevereWithTracker(String tracker, String entityId, String msg) {
    logWithTracker(ApplicationLog.DEFAULT_LOG, tracker, entityId, msg, Level.ERROR);
  }

  private void logWithTracker(
      ApplicationLog log, String tracker, String entityId, String msg, Level level) {
    logWithTracker(log, tracker, entityId, msg, level, new Object[] {});
  }

  public void logTagHistory(TagHistoryLogEntry l, String tracker) {

    Object[] attributes =
        new Object[] {
          kv("tag_history_log_project_id", l.tableSpec().project()),
          kv("tag_history_log_dataset_id", l.tableSpec().dataset()),
          kv("tag_history_log_table_id", l.tableSpec().table()),
          kv("tag_history_log_field_name", l.fieldName()),
          kv("tag_history_log_existing_policy_tag_id", l.existingPolicyTagId()),
          kv("tag_history_log_new_policy_tag_id", l.newPolicyTagId()),
          kv("tag_history_log_column_tagging_action", l.columnTaggingAction().toString()),
          kv("tag_history_log_description", l.newPolicyTagId()),
        };

    logWithTracker(
        ApplicationLog.TAG_HISTORY_LOG,
        tracker,
        l.tableSpec().toSqlString(),
        l.toLogString(),
        l.logLevel(),
        attributes);
  }

  public void logLabelsHistory(
      TableSpec tableSpec,
      String labelKey,
      String labelValue,
      Boolean isDryRun,
      ResourceLabelingAction action,
      String tracker) {

    Object[] attributes =
        new Object[] {
          kv("labels_history_log_project_id", tableSpec.project()),
          kv("labels_history_log_dataset_id", tableSpec.dataset()),
          kv("labels_history_log_table_id", tableSpec.table()),
          kv("labels_history_log_label_key", labelKey),
          kv("labels_history_log_label_value", labelValue),
          kv("labels_history_log_label_action", action),
          kv("labels_history_log_is_dry_run", isDryRun),
        };

    logWithTracker(
        ApplicationLog.LABEL_HISTORY_LOG,
        tracker,
        tableSpec.toSqlString(),
        String.format(
            "Labels: table  %s, isDryRunLabels = %s, action = %s ,KV (%s, %s)",
            tableSpec.toSqlString(), isDryRun, action, labelKey, labelValue),
        Level.INFO,
        attributes);
  }

  public void logBucketLabelsHistory(
      String bucketName,
      String bucketProject,
      String labelKey,
      String labelValue,
      Boolean isDryRun,
      ResourceLabelingAction action,
      String tracker) {

    Object[] attributes =
        new Object[] {
          kv("labels_history_log_bucket_name", bucketName),
          kv("labels_history_log_project_id", bucketProject),
          kv("labels_history_log_label_key", labelKey),
          kv("labels_history_log_label_value", labelValue),
          kv("labels_history_log_label_action", action),
          kv("labels_history_log_is_dry_run", isDryRun),
        };

    logWithTracker(
        ApplicationLog.GCS_LABEL_HISTORY_LOG,
        tracker,
        Utils.generateBucketEntityId(bucketProject, bucketName),
        String.format(
            "Labels: bucket  %s, isDryRunLabels = %s, action = %s ,KV (%s, %s)",
            bucketName, isDryRun, action, labelKey, labelValue),
        Level.INFO,
        attributes);
  }

  public void logSuccessDispatcherTrackingId(
      String trackingId, String dispatchedTrackingId, TableSpec tableSpec) {

    Object[] attributes =
        new Object[] {
          kv("dispatched_tracking_id", dispatchedTrackingId),
          kv("dispatched_tablespec", tableSpec.toSqlString()),
          kv("dispatched_tablespec_project", tableSpec.project()),
          kv("dispatched_tablespec_dataset", tableSpec.dataset()),
          kv("dispatched_tablespec_table", tableSpec.table()),
        };

    logWithTracker(
        ApplicationLog.DISPATCHED_REQUESTS_LOG,
        trackingId,
        tableSpec.toSqlString(),
        String.format("Dispatched request with trackindId `%s`", dispatchedTrackingId),
        Level.INFO,
        attributes);
  }

  // To log failed processing of projects, datasets or tables
  public void logNonRetryableExceptions(String trackingId, String entityId, Exception ex) {

    Object[] attributes =
        new Object[] {
          kv("non_retryable_ex_tracking_id", trackingId),
          kv("non_retryable_ex_name", ex.getClass().getName()),
          kv("non_retryable_ex_msg", ex.getMessage()),
        };

    logWithTracker(
        ApplicationLog.NON_RETRYABLE_EXCEPTIONS_LOG,
        trackingId,
        entityId,
        String.format(
            "Caught a Non-Retryable exception while processing tracker `%s`. Exception: %s. Msg:"
                + " %s",
            trackingId, ex.getClass().getName(), ex.getMessage()),
        Level.ERROR,
        attributes);
    ex.printStackTrace();
  }

  // To log failed processing of projects, datasets or tables
  public void logRetryableExceptions(
      String trackingId, String entityId, Exception ex, String reason) {

    Object[] attributes =
        new Object[] {
          kv("retryable_ex_tracking_id", trackingId),
          kv("retryable_ex_name", ex.getClass().getName()),
          kv("retryable_ex_msg", ex.getMessage()),
          kv("retryable_ex_reason", reason),
        };

    logWithTracker(
        ApplicationLog.RETRYABLE_EXCEPTIONS_LOG,
        trackingId,
        entityId,
        String.format(
            "Caught a Retryable exception while processing tracker `%s`. Exception: %s. Msg: %s."
                + " Classification Reason: %s.",
            trackingId, ex.getClass().getName(), ex.getMessage(), reason),
        Level.WARN,
        attributes);
    ex.printStackTrace();
  }

  public void logFunctionStart(String trackingId, String entityId) {
    logFunctionLifeCycleEvent(trackingId, entityId, FunctionLifeCycleEvent.START);
  }

  public void logFunctionEnd(String trackingId, String entityId) {
    logFunctionLifeCycleEvent(trackingId, entityId, FunctionLifeCycleEvent.END);
  }

  private void logFunctionLifeCycleEvent(
      String trackingId, String entityId, FunctionLifeCycleEvent event) {

    Object[] attributes =
        new Object[] {
          kv("function_lifecycle_event", event),
          kv("function_lifecycle_functionNumber", functionNumber),
        };

    logWithTracker(
        ApplicationLog.TRACKER_LOG,
        trackingId,
        entityId,
        String.format("%s | %s | %s", loggerName, functionNumber, event),
        Level.INFO,
        attributes);
  }

  private void logWithTracker(
      ApplicationLog log,
      String tracker,
      String entityId,
      String msg,
      Level level,
      Object[] extraAttributes) {

    // Enable JSON logging with Logback and SLF4J by enabling the Logstash JSON Encoder in your
    // logback.xml configuration.

    String payload =
        String.format("%s | %s | %s | %s | %s", applicationName, log, loggerName, tracker, msg);

    String runId;
    try {
      runId = TrackingHelper.parseRunIdAsPrefix(tracker);
    } catch (Exception e) {
      // so that it never appears in max(run_id) queries
      runId = "0000000000000-z";
    }

    Object[] globalAttributes =
        new Object[] {
          kv("global_app", this.applicationName),
          kv("global_logger_name", this.loggerName),
          kv("global_app_log", log),
          kv("global_tracker", tracker),
          kv("global_run_id", runId),
          kv("global_entity_id", entityId),
          kv("global_msg", msg),
          kv("severity", level.toString()),

          // Group all log entries with the same tracker in CLoud Logging iew
          kv(
              "logging.googleapis.com/trace",
              String.format("projects/%s/traces/%s", projectId, tracker))
        };

    // setting the "severity" KV will override the logger.<severity>
    logger.info(
        payload,
        Stream.concat(Arrays.stream(globalAttributes), Arrays.stream(extraAttributes)).toArray());
  }
}
