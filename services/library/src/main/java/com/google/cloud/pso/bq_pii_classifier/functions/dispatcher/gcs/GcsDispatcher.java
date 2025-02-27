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

  private BigQueryService bqService;
  private PubSubService pubSubService;

  private DlpResultsForGcsScanner scanner;
  private GcsDispatcherConfig config;
  private PersistentSet persistentSet;
  private String persistentSetObjectPrefix;
  private String runId;

  public GcsDispatcher(
          GcsDispatcherConfig config,
          BigQueryService bqService,
          PubSubService pubSubService,
          DlpResultsForGcsScanner scanner,
          PersistentSet persistentSet,
          String persistentSetObjectPrefix,
          String runId) {

    this.config = config;
    this.bqService = bqService;
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

    long startTimeMilis = System.currentTimeMillis();

    // Configure how many messages the publisher client can hold in memory
    // and what to do when messages exceed the limit.
    FlowControlSettings flowControlSettings =
            FlowControlSettings.newBuilder()
                    // Block more messages from being published when the limit is reached. The other
                    // options are Ignore (or continue publishing) and ThrowException (or error out).
                    .setLimitExceededBehavior(FlowController.LimitExceededBehavior.Block)
                    .setMaxOutstandingRequestBytes(10 * 1024 * 1024L) // 10 MiB
                    .setMaxOutstandingElementCount(1000L) // 100 messages
                    .build();

    // Configure batching settings
    BatchingSettings batchingSettings = BatchingSettings.newBuilder()
            .setElementCountThreshold(100L) // default: 100 messages, max 1000
            .setRequestByteThreshold(1000000L) // default: 1000 bytes // max 10mb this makes it faster
            .setDelayThreshold(Duration.ofMillis(1)) // default: 1 ms
            .setFlowControlSettings(flowControlSettings)
            .build();


    // Configure retry settings
    RetrySettings retrySettings = RetrySettings.newBuilder()
            .setInitialRetryDelay(Duration.ofMillis(100)) // default: 100 ms
            .setRetryDelayMultiplier(2.0) // default: 1.3
            .setMaxRetryDelay(Duration.ofSeconds(60)) // default: 60 seconds
            .setInitialRpcTimeout(Duration.ofSeconds(1)) // default: 5 seconds
            .setRpcTimeoutMultiplier(1.0) // default: 1.0
            .setMaxRpcTimeout(Duration.ofSeconds(600)) // default: 600 seconds
            .setTotalTimeout(Duration.ofSeconds(600)) // default: 600 seconds
            .build();

    // Provides an executor service for processing messages. The default
    // `executorProvider` used by the publisher has a default thread count of
    // 5 * the number of processors available to the Java virtual machine.
    ExecutorProvider executorProvider =
            InstantiatingExecutorProvider.newBuilder()
                    .setExecutorThreadCount(5 * Runtime.getRuntime().availableProcessors())
                    .build();

    // Create a publisher instance with batching and retry settings
    Publisher publisher = Publisher.newBuilder(TopicName.of(config.getProjectId(), config.getOutputTopic()))
            .setBatchingSettings(batchingSettings)
            .setRetrySettings(retrySettings)
            .setExecutorProvider(executorProvider)
            .build();


    // Publish each row to Pub/Sub and stream to BigQuery
    List<ApiFuture<String>> futures = new ArrayList<>();
    AtomicInteger bqRowsCounter = new AtomicInteger(0);
    AtomicInteger successfulPublishes = new AtomicInteger(0); // Counter for successful publishes
    AtomicInteger failedPublishes = new AtomicInteger(0);

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


    for (FieldValueList row: dlpFindingsQueryResults.iterateAll()) {
      bqRowsCounter.incrementAndGet();

      String bucketName = row.get("bucket_name").getStringValue();
      String projectId = row.get("project_id").getStringValue();
      String infoTypesStrList = row.get("info_types").getStringValue();

      String trackingId = TrackingHelper.generateTrackingId(runId, bucketName);
      GcsTaggerRequest taggerRequest = new GcsTaggerRequest(
              runId,
              trackingId,
              new GcsDlpProfileSummary(
                      bucketName,
                      projectId,
                      new HashSet<>(Utils.tokenize(infoTypesStrList, ",", true))
              )
      );

      ByteString data = ByteString.copyFromUtf8(taggerRequest.toJsonString());
      ApiFuture<String> future = publisher.publish(
              PubsubMessage.newBuilder()
                      .setData(data)
                      .build());

      // Add a callback to handle publish result and stream to BigQuery
      ApiFutures.addCallback(future, new ApiFutureCallback<>() {
        @Override
        public void onFailure(Throwable throwable) {
          failedPublishes.incrementAndGet();
          //System.err.println("Error publishing message: " + throwable.getMessage());
          // Handle error, e.g., log or store in an error table
          logger.logFailedGcsDispatcherEntityId(
                  runId,
                  throwable
          );
        }

        @Override
        public void onSuccess(String messageId) {
          successfulPublishes.incrementAndGet();
          if(successfulPublishes.get() % 1000000 == 0){
            long elapsedSeconds = (System.currentTimeMillis() - startTimeMilis) / 1000;
            logger.logInfoWithTracker(runId,
                    String.format("PubSub successful messages count so far: %s after %s seconds ( %s mins)",
                            successfulPublishes.get(),
                            elapsedSeconds,
                            elapsedSeconds/60
                            ));
          }
        }
      });

      futures.add(future);
    }

    // Wait for all publish futures to complete
    ApiFutures.allAsList(futures).get();

    // Shutdown the publisher
    publisher.shutdown();
    publisher.awaitTermination(1, TimeUnit.MINUTES);

    long endTimeMilis = System.currentTimeMillis();

    logger.logInfoWithTracker(runId,
            String.format("Total profiles fetched and processed from BigQuery : %s", bqRowsCounter.get()));

    logger.logInfoWithTracker(runId,
            String.format("Total PubSub successful messages : %s", successfulPublishes.get()));

    logger.logInfoWithTracker(runId,
            String.format("Total PubSub failed messages : %s", failedPublishes.get()));

    logger.logInfoWithTracker(runId,
            String.format("Total duration in seconds : %s", (endTimeMilis-startTimeMilis)/1000));


    logger.logFunctionEnd(runId);
  }
}
