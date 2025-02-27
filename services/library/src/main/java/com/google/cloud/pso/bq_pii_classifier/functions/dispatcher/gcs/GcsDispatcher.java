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

package com.google.cloud.pso.bq_pii_classifier.functions.dispatcher.gcs;

import com.google.api.core.ApiFuture;
import com.google.api.core.ApiFutureCallback;
import com.google.api.core.ApiFutures;
import com.google.api.gax.batching.BatchingSettings;
import com.google.api.gax.batching.FlowControlSettings;
import com.google.api.gax.batching.FlowController;
import com.google.api.gax.core.ExecutorProvider;
import com.google.api.gax.core.InstantiatingExecutorProvider;
import com.google.api.gax.retrying.RetrySettings;
import com.google.cloud.bigquery.*;
import com.google.cloud.pso.bq_pii_classifier.entities.*;
import com.google.cloud.pso.bq_pii_classifier.functions.tagger.gcs.GcsTaggerRequest;
import com.google.cloud.pso.bq_pii_classifier.helpers.LoggingHelper;
import com.google.cloud.pso.bq_pii_classifier.helpers.TrackingHelper;
import com.google.cloud.pso.bq_pii_classifier.helpers.Utils;
import com.google.cloud.pso.bq_pii_classifier.services.bq.BigQueryService;
import com.google.cloud.pso.bq_pii_classifier.services.pubsub.PubSubService;
import com.google.cloud.pso.bq_pii_classifier.services.scan.gcs.DlpResultsForGcsScanner;
import com.google.cloud.pso.bq_pii_classifier.services.set.PersistentSet;
import com.google.cloud.pubsub.v1.Publisher;
import com.google.common.io.Resources;
import com.google.protobuf.ByteString;
import com.google.pubsub.v1.PubsubMessage;
import com.google.pubsub.v1.TopicName;
import org.threeten.bp.Duration;

import java.io.IOException;
import java.nio.charset.StandardCharsets;
import java.util.ArrayList;
import java.util.HashSet;
import java.util.List;
import java.util.Set;
import java.util.concurrent.ExecutionException;
import java.util.concurrent.TimeUnit;
import java.util.concurrent.atomic.AtomicInteger;

public class GcsDispatcher {

  private static final Integer functionNumber = 1;

  private final LoggingHelper logger;
  private PubSubService pubSubService;

  private DlpResultsForGcsScanner scanner;
  private GcsDispatcherConfig config;
  private PersistentSet persistentSet;
  private String persistentSetObjectPrefix;
  private String runId;

  public GcsDispatcher(
          GcsDispatcherConfig config,
          PubSubService pubSubService,
          DlpResultsForGcsScanner scanner,
          PersistentSet persistentSet,
          String persistentSetObjectPrefix,
          String runId) {

    this.config = config;
    this.pubSubService = pubSubService;
    this.scanner = scanner;
    this.persistentSet = persistentSet;
    this.persistentSetObjectPrefix = persistentSetObjectPrefix;
    this.runId = runId;

    logger =
            new LoggingHelper(
                    GcsDispatcher.class.getSimpleName(), functionNumber, config.getProjectId());
  }

  public void execute(GcsScope scope, String pubSubMessageId)
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

      logger.logWarnWithTracker(runId, msg);
      return;

    } else {
      logger.logInfoWithTracker(
              runId,
              String.format("Persisting processing key for PubSub message ID %s", pubSubMessageId));
      persistentSet.add(flagFileName);
    }

    logger.logInfoWithTracker(runId, "Executing the BigQuery query..");
    TableResult dlpFindingsQueryResults = scanner.getGcsDlpProfilesFromBigQuery(
            config.getProjectId(),
            config.getDlpResultsDatasetName(),
            config.getDlpResultsTableName(),
            config.getDispatcherRunsTableName(),
            scope.getBucketsRegex(),
            scope.getProjectsRegex(),
            runId
    );
    logger.logInfoWithTracker(runId,
            String.format("BigQuery query returned %s rows", dlpFindingsQueryResults.getTotalRows()));

    pubSubService.publishBigQueryTableResults(dlpFindingsQueryResults,
            config.getProjectId(),
            config.getOutputTopic(),
            runId,
            logger,
            1000);

    logger.logFunctionEnd(runId);
  }
}
