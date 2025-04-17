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

package com.google.cloud.pso.bq_pii_classifier.functions.dispatcher;

import com.google.cloud.bigquery.*;
import com.google.cloud.pso.bq_pii_classifier.entities.NonRetryableApplicationException;
import com.google.cloud.pso.bq_pii_classifier.helpers.LoggingHelper;
import com.google.cloud.pso.bq_pii_classifier.services.pubsub.BigQueryToPubSubStreamer;
import com.google.cloud.pso.bq_pii_classifier.services.scan.DlpFindingsScanner;
import com.google.cloud.pso.bq_pii_classifier.services.set.PersistentSet;
import java.io.IOException;
import java.util.concurrent.ExecutionException;

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

  public void execute()
      throws IOException,
          NonRetryableApplicationException,
          InterruptedException,
          ExecutionException {

    logger.logInfoWithTracker(runId, null, "Executing the BigQuery query..");

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
