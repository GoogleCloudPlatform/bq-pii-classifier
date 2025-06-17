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

package com.google.cloud.oss.solutions.annotations.services.pubsub;

import com.google.cloud.bigquery.TableResult;
import com.google.cloud.oss.solutions.annotations.entities.NonRetryableApplicationException;
import com.google.cloud.oss.solutions.annotations.helpers.LoggingHelper;
import java.io.IOException;
import java.util.concurrent.ExecutionException;

/** Interface for streaming BigQuery results to PubSub. */
public interface BigQueryToPubSubStreamer {

  /**
   * Publishes BigQuery table results to a PubSub topic.
   *
   * @param bqTableResults The BigQuery table results to publish.
   * @param pubSubProjectId The ID of the GCP project containing the PubSub topic.
   * @param pubSubTopic The name of the PubSub topic to publish to.
   * @param runId The ID of the current run.
   * @param logger The logger to use for logging.
   * @param successMessagesIntervalForLogging The interval at which to log success messages.
   * @throws IOException If an I/O error occurs.
   * @throws ExecutionException If an error occurs during execution.
   * @throws InterruptedException If the thread is interrupted.
   * @throws NonRetryableApplicationException If a non-retryable error occurs.
   */
  void publishBigQueryTableResults(
      TableResult bqTableResults,
      String pubSubProjectId,
      String pubSubTopic,
      String runId,
      LoggingHelper logger,
      long successMessagesIntervalForLogging)
      throws IOException,
          ExecutionException,
          InterruptedException,
          NonRetryableApplicationException;
}
