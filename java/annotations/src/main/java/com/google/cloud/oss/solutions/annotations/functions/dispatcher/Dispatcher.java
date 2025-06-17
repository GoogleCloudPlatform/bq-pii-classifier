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

package com.google.cloud.oss.solutions.annotations.functions.dispatcher;

import com.google.cloud.bigquery.TableResult;
import com.google.cloud.oss.solutions.annotations.entities.NonRetryableApplicationException;
import com.google.cloud.oss.solutions.annotations.helpers.LoggingHelper;
import com.google.cloud.oss.solutions.annotations.services.pubsub.BigQueryToPubSubStreamer;
import com.google.cloud.oss.solutions.annotations.services.scan.DlpFindingsScanner;
import java.io.IOException;
import java.util.concurrent.ExecutionException;

/**
 * Dispatcher class that orchestrates the process of fetching DLP findings from BigQuery and
 * publishing them to a Pub/Sub topic.
 */
public class Dispatcher {

  private static final Integer functionNumber = 1;
  private final LoggingHelper logger;
  private final BigQueryToPubSubStreamer bigQueryToPubSubStreamer;
  private final DlpFindingsScanner scanner;
  private final DispatcherConfig config;
  private final String runId;

  public Dispatcher(
      DispatcherConfig config,
      BigQueryToPubSubStreamer bigQueryToPubSubStreamer,
      DlpFindingsScanner scanner,
      String runId) {

    this.config = config;
    this.bigQueryToPubSubStreamer = bigQueryToPubSubStreamer;
    this.scanner = scanner;
    this.runId = runId;

    logger =
        new LoggingHelper(Dispatcher.class.getSimpleName(), functionNumber, config.projectId());
  }

  /**
   * Executes the main logic of the dispatcher.
   *
   * <p>This includes:
   *
   * <ul>
   *   <li>Fetching DLP profiles from BigQuery.
   *   <li>Publishing the fetched data to a Pub/Sub topic.
   * </ul>
   *
   * @throws IOException If an I/O error occurs.
   * @throws NonRetryableApplicationException If a non-retryable error occurs during processing.
   * @throws InterruptedException If the thread is interrupted during execution.
   * @throws ExecutionException If an error occurs during asynchronous task execution.
   */
  public void execute()
      throws IOException,
          NonRetryableApplicationException,
          InterruptedException,
          ExecutionException {

    logger.logInfoWithTracker(
        runId,
        null,
        String.format(
            "Using BigQueryToPubSubStreamer with settings: %s",
            bigQueryToPubSubStreamer.toString()));

    logger.logInfoWithTracker(runId, null, "Executing the Dispatcher BigQuery query..");

    TableResult dlpFindingsQueryResults = scanner.getDlpProfilesFromBigQuery(runId);

    logger.logInfoWithTracker(
        runId,
        null,
        String.format("BigQuery query returned %s rows", dlpFindingsQueryResults.getTotalRows()));

    bigQueryToPubSubStreamer.publishBigQueryTableResults(
        dlpFindingsQueryResults, config.projectId(), config.outputTopic(), runId, logger, 1000);

    logger.logFunctionEnd(runId, null);
  }
}
