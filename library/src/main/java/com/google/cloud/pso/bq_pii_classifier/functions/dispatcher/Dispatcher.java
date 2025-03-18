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
import com.google.cloud.pso.bq_pii_classifier.helpers.LoggingHelper;
import com.google.cloud.pso.bq_pii_classifier.services.pubsub.BigQueryToPubSubStreamer;
import com.google.cloud.pso.bq_pii_classifier.services.scan.DlpFindingsScanner;
import com.google.cloud.pso.bq_pii_classifier.services.set.PersistentSet;
import com.google.cloud.pso.bq_pii_classifier.entities.NonRetryableApplicationException;

import java.io.IOException;
import java.util.concurrent.ExecutionException;

public class Dispatcher {

  private static final Integer functionNumber = 1;
  private final LoggingHelper logger;
  private final BigQueryToPubSubStreamer bigQueryToPubSubStreamer;
  private final DlpFindingsScanner scanner;
  private final DispatcherConfig config;
  private final PersistentSet persistentSet;
  private final String persistentSetObjectPrefix;
  private final String runId;

  public Dispatcher(
          DispatcherConfig config,
          BigQueryToPubSubStreamer bigQueryToPubSubStreamer,
          DlpFindingsScanner scanner,
          PersistentSet persistentSet,
          String persistentSetObjectPrefix,
          String runId) {

    this.config = config;
    this.bigQueryToPubSubStreamer = bigQueryToPubSubStreamer;
    this.scanner = scanner;
    this.persistentSet = persistentSet;
    this.persistentSetObjectPrefix = persistentSetObjectPrefix;
    this.runId = runId;

    logger =
            new LoggingHelper(
                    Dispatcher.class.getSimpleName(), functionNumber, config.projectId());
  }

  public void execute(String pubSubMessageId)
          throws IOException, NonRetryableApplicationException, InterruptedException, ExecutionException {

    /**
     * Check if we already processed this pubSubMessageId before to avoid re-running the dispatcher
     * (and the whole process) in case we have unexpected errors with PubSub re-sending the message.
     * This is an extra measure to avoid unnecessary cost. We do that by keeping simple flag files
     * in GCS with the pubSubMessageId as file name.
     */
    String flagFileName = String.format("%s/%s", persistentSetObjectPrefix, pubSubMessageId);
    if (persistentSet.contains(flagFileName)) {
      // log error and ACK and return
      String msg =
              String.format(
                      "PubSub message ID '%s' has been processed before. "
                              + "This is probably retried by PubSub due to it's subscription_ack_deadline_seconds being"
                              + " 10min or less (max) while the dispatcher process is taking more. The message is not "
                              + "going to be re-processed and ignored instead.",
                      pubSubMessageId);

      logger.logWarnWithTracker(runId, null, msg);
      return;

    } else {
      logger.logInfoWithTracker(
              runId,
              null,
              String.format("Persisting processing key for PubSub message ID %s", pubSubMessageId));
      persistentSet.add(flagFileName);
    }

    logger.logInfoWithTracker(runId, null, "Executing the BigQuery query..");

    TableResult dlpFindingsQueryResults = scanner.getDlpProfilesFromBigQuery(runId);

    logger.logInfoWithTracker(
            runId,
            null,
            String.format("BigQuery query returned %s rows", dlpFindingsQueryResults.getTotalRows()));

    bigQueryToPubSubStreamer.publishBigQueryTableResults(dlpFindingsQueryResults,
            config.projectId(),
            config.outputTopic(),
            runId,
            logger,
            1000);

    logger.logFunctionEnd(runId, null);
  }
}
