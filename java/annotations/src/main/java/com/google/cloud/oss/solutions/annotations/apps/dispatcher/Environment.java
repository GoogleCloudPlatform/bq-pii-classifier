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

import com.google.cloud.oss.solutions.annotations.functions.dispatcher.DispatcherConfig;
import com.google.cloud.oss.solutions.annotations.helpers.Utils;

/** Environment class to get all the environment variables needed for the dispatcher. */
public class Environment {

  public DispatcherConfig toConfig() {

    return new DispatcherConfig(getProjectId(), getTaggerTopic());
  }

  public String getProjectId() {
    return Utils.getConfigFromEnv("PROJECT_ID", true);
  }

  public String getPublishingProjectId() {
    return Utils.getConfigFromEnv("PUBLISHING_PROJECT_ID", true);
  }

  public String getTaggerTopic() {
    return Utils.getConfigFromEnv("TAGGER_TOPIC", true);
  }

  public String getDlpResultsDataset() {
    return Utils.getConfigFromEnv("DLP_RESULTS_DATASET", true);
  }

  public String getLoggingDataset() {
    return Utils.getConfigFromEnv("LOGGING_DATASET", true);
  }

  public String getDlpResultsTable() {
    return Utils.getConfigFromEnv("DLP_RESULTS_TABLE", true);
  }

  public String getDispatcherRunsTable() {
    return Utils.getConfigFromEnv("DISPATCHER_RUNS_TABLE", true);
  }

  // PubSub
  public Long getPubSubFlowControlMaxOutstandingRequestBytes() {
    return Long.parseLong(
        Utils.getConfigFromEnv("PUBSUB_FLOW_CONTROL_MAX_OUTSTANDING_REQUESTS_BYTES", true));
  }

  public Long getPubSubFlowControlMaxOutstandingElementCount() {
    return Long.parseLong(
        Utils.getConfigFromEnv("PUBSUB_FLOW_CONTROL_MAX_OUTSTANDING_ELEMENT_COUNT", true));
  }

  public Long getPubSubBatchingElementCountThreshold() {
    return Long.parseLong(Utils.getConfigFromEnv("PUBSUB_BATCHING_ELEMENT_COUNT_THRESHOLD", true));
  }

  public Long getPubSubBatchingRequestByteThreshold() {
    return Long.parseLong(Utils.getConfigFromEnv("PUBSUB_BATCHING_REQUEST_BYTE_THRESHOLD", true));
  }

  public Long getPubSubBatchingDelayThresholdMillis() {
    return Long.parseLong(Utils.getConfigFromEnv("PUBSUB_BATCHING_DELAY_THRESHOLD_MILLIS", true));
  }

  public Long getPubSubRetryInitialRetryDelayMillis() {
    return Long.parseLong(Utils.getConfigFromEnv("PUBSUB_RETRY_INITIAL_RETRY_DELAY_MILLIS", true));
  }

  public Double getPubSubRetryRetryDelayMultiplier() {
    return Double.parseDouble(Utils.getConfigFromEnv("PUBSUB_RETRY_RETRY_DELAY_MULTIPLIER", true));
  }

  public Long getPubSubRetryMaxRetryDelaySeconds() {
    return Long.parseLong(Utils.getConfigFromEnv("PUBSUB_RETRY_MAX_RETRY_DELAY_SECONDS", true));
  }

  public Long getPubSubRetryInitialRpcTimeoutSeconds() {
    return Long.parseLong(Utils.getConfigFromEnv("PUBSUB_RETRY_INITIAL_RPC_TIMEOUT_SECONDS", true));
  }

  public Double getPubSubRetryRpcTimeoutMultiplier() {
    return Double.parseDouble(Utils.getConfigFromEnv("PUBSUB_RETRY_RPC_TIMEOUT_MULTIPLIER", true));
  }

  public Long getPubSubRetryMaxRpcTimeoutSeconds() {
    return Long.parseLong(Utils.getConfigFromEnv("PUBSUB_RETRY_MAX_RPC_TIMEOUT_SECONDS", true));
  }

  public Long getPubSubRetryTotalTimeoutSeconds() {
    return Long.parseLong(Utils.getConfigFromEnv("PUBSUB_RETRY_TOTAL_TIMEOUT_SECONDS", true));
  }

  public Integer getPubSubExecutorThreadCountMultiplier() {
    return Integer.parseInt(
        Utils.getConfigFromEnv("PUBSUB_EXECUTOR_THREAD_COUNT_MULTIPLIER", true));
  }
}
