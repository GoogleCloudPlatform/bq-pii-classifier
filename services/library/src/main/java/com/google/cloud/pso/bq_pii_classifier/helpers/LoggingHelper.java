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

package com.google.cloud.pso.bq_pii_classifier.helpers;

import com.google.cloud.pso.bq_pii_classifier.entities.ApplicationLog;
import com.google.cloud.pso.bq_pii_classifier.entities.FunctionLifeCycleEvent;
import com.google.cloud.pso.bq_pii_classifier.entities.TableSpec;
import com.google.cloud.pso.bq_pii_classifier.entities.TagHistoryLogEntry;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.slf4j.event.Level;

import java.util.Arrays;
import java.util.stream.Stream;

import static net.logstash.logback.argument.StructuredArguments.kv;

public class LoggingHelper {

    private final Logger logger;
    private final String loggerName;
    private final Integer functionNumber;
    // Used to create a trace
    private final String projectId;

    private final String applicationName = "bq-pii-classifier";

    public LoggingHelper(String loggerName, Integer functionNumber, String projectId) {
        this.loggerName = loggerName;
        this.functionNumber = functionNumber;
        this.projectId = projectId;

        logger = LoggerFactory.getLogger(loggerName);
    }

    public void logInfoWithTracker(String tracker, String msg) {
        logWithTracker(ApplicationLog.DEFAULT_LOG, tracker, msg, Level.INFO);
    }

    public void logWarnWithTracker(String tracker, String msg) {
        logWithTracker(ApplicationLog.DEFAULT_LOG, tracker, msg, Level.WARN);
    }

    public void logSevereWithTracker(String tracker, String msg) {
        logWithTracker(ApplicationLog.DEFAULT_LOG, tracker, msg, Level.ERROR);
    }

    private void logWithTracker(ApplicationLog log, String tracker, String msg, Level level) {
        logWithTracker(log, tracker, msg, level, new Object[]{});
    }

    public void logTagHistory(TagHistoryLogEntry l, String tracker){

        Object [] attributes = new Object[]{
                kv("tag_history_log_project_id", l.getTableSpec().getProject()),
                kv("tag_history_log_dataset_id", l.getTableSpec().getDataset()),
                kv("tag_history_log_table_id", l.getTableSpec().getTable()),
                kv("tag_history_log_field_name", l.getFieldName()),
                kv("tag_history_log_existing_policy_tag_id", l.getExistingPolicyTagId()),
                kv("tag_history_log_new_policy_tag_id", l.getNewPolicyTagId()),
                kv("tag_history_log_column_tagging_action", l.getColumnTaggingAction().toString()),
                kv("tag_history_log_description", l.getNewPolicyTagId()),
        };

        logWithTracker(
                ApplicationLog.TAG_HISTORY_LOG,
                tracker,
                l.toLogString(),
                l.getLogLevel(),
                attributes
        );

    }

    public void logSuccessDispatcherTrackingId(String trackingId, String dispatchedTrackingId, TableSpec tableSpec) {

        Object [] attributes = new Object[]{
                kv("dispatched_tracking_id", dispatchedTrackingId),
                kv("dispatched_tablespec", tableSpec.toSqlString()),
                kv("dispatched_tablespec_project", tableSpec.getProject()),
                kv("dispatched_tablespec_dataset", tableSpec.getDataset()),
                kv("dispatched_tablespec_table", tableSpec.getTable()),
        };

        logWithTracker(
                ApplicationLog.DISPATCHED_REQUESTS_LOG,
                trackingId,
                String.format("Dispatched tagging request with trackindId `%s`", dispatchedTrackingId),
                Level.INFO,
                attributes
        );
    }

    // To log failed processing of projects, datasets or tables
    public void logFailedDispatcherEntityId(String trackingId, String entityId, Exception ex) {

        Object [] attributes = new Object[]{
                kv("failed_dispatcher_entity_id", entityId),
                kv("failed_dispatcher_ex_name", ex.getClass().getName()),
                kv("failed_dispatcher_ex_msg", ex.getMessage())
        };

        logWithTracker(
                ApplicationLog.FAILED_DISPATCHED_REQUESTS_LOG,
                trackingId,
                String.format("Failed to process entity `%s`.Exception: %s. Msg: %s",
                        entityId,
                        ex.getClass().getName(),
                        ex.getMessage()
                        ),
                Level.ERROR,
                attributes
        );
    }

    // To log failed processing of projects, datasets or tables
    public void logNonRetryableExceptions(String trackingId, Exception ex) {

        Object [] attributes = new Object[]{
                kv("non_retryable_ex_tracking_id", trackingId),
                kv("non_retryable_ex_name", ex.getClass().getName()),
                kv("non_retryable_ex_msg", ex.getMessage()),
        };

        logWithTracker(
                ApplicationLog.NON_RETRYABLE_EXCEPTIONS_LOG,
                trackingId,
                String.format("Caught a Non-Retryable exception while processing tracker `%s`. Exception: %s. Msg: %s", trackingId, ex.getClass().getName(), ex.getMessage()),
                Level.ERROR,
                attributes
        );
    }

    // To log failed processing of projects, datasets or tables
    public void logRetryableExceptions(String trackingId, Exception ex) {

        Object [] attributes = new Object[]{
                kv("retryable_ex_tracking_id", trackingId),
                kv("retryable_ex_name", ex.getClass().getName()),
                kv("retryable_ex_msg", ex.getMessage()),
        };

        logWithTracker(
                ApplicationLog.RETRYABLE_EXCEPTIONS_LOG,
                trackingId,
                String.format("Caught a Retryable exception while processing tracker `%s`. Exception: %s. Msg: %s", trackingId, ex.getClass().getName(), ex.getMessage()),
                Level.WARN,
                attributes
        );
    }

    public void logFunctionStart(String trackingId) {
        logFunctionLifeCycleEvent(trackingId, FunctionLifeCycleEvent.START);
    }

    public void logFunctionEnd(String trackingId) {
        logFunctionLifeCycleEvent(trackingId, FunctionLifeCycleEvent.END);
    }

    private void logFunctionLifeCycleEvent(String trackingId, FunctionLifeCycleEvent event) {

        Object [] attributes = new Object[]{
                kv("function_lifecycle_event", event),
                kv("function_lifecycle_functionNumber", functionNumber),
        };

        logWithTracker(
                ApplicationLog.TRACKER_LOG,
                trackingId,
                String.format("%s | %s | %s",
                        loggerName,
                        functionNumber,
                        event),
                Level.INFO,
                attributes
        );

    }

    private void logWithTracker(ApplicationLog log, String tracker, String msg, Level level, Object [] extraAttributes) {

        // Enable JSON logging with Logback and SLF4J by enabling the Logstash JSON Encoder in your logback.xml configuration.

        String payload = String.format("%s | %s | %s | %s | %s",
                applicationName,
                log,
                loggerName,
                tracker,
                msg
        );

        String runId;
        try{
            runId = TrackingHelper.parseRunIdAsPrefix(tracker);
        }catch (Exception e){
            runId = "NA";
        }

        Object [] globalAttributes = new Object[]{
                kv("global_app", this.applicationName),
                kv("global_logger_name", this.loggerName),
                kv("global_app_log", log),
                kv("global_tracker", tracker),
                kv("global_run_id", runId),
                kv("global_msg", msg),
                kv("severity", level.toString()),

                // Group all log entries with the same tracker in CLoud Logging iew
                kv("logging.googleapis.com/trace",
                        String.format("projects/%s/traces/%s", projectId, tracker))
        };

        // setting the "severity" KV will override the logger.<severity>
        logger.info(
                payload,
                Stream.concat(
                        Arrays.stream(globalAttributes),
                        Arrays.stream(extraAttributes)
                ).toArray()
        );
    }
}
