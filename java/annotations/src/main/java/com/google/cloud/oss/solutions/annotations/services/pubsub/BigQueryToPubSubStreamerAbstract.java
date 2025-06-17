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

import com.google.api.core.ApiFuture;
import com.google.api.core.ApiFutureCallback;
import com.google.api.core.ApiFutures;
import com.google.api.gax.batching.BatchingSettings;
import com.google.api.gax.batching.FlowControlSettings;
import com.google.api.gax.batching.FlowController;
import com.google.api.gax.core.ExecutorProvider;
import com.google.api.gax.core.InstantiatingExecutorProvider;
import com.google.api.gax.retrying.RetrySettings;
import com.google.cloud.bigquery.FieldValueList;
import com.google.cloud.bigquery.TableResult;
import com.google.cloud.pubsub.v1.Publisher;
import com.google.cloud.oss.solutions.annotations.entities.NonRetryableApplicationException;
import com.google.cloud.oss.solutions.annotations.helpers.LoggingHelper;
import com.google.pubsub.v1.PubsubMessage;
import com.google.pubsub.v1.TopicName;
import java.io.IOException;
import java.util.ArrayList;
import java.util.List;
import java.util.concurrent.ExecutionException;
import java.util.concurrent.TimeUnit;
import java.util.concurrent.atomic.AtomicInteger;
import org.threeten.bp.Duration;

/**
 * Abstract class to stream BigQuery results to PubSub.
 *
 * <p>It handles the creation of the PubSub publisher, the batching and retry settings, and the
 * publishing of messages.
 */
public abstract class BigQueryToPubSubStreamerAbstract implements BigQueryToPubSubStreamer {

  private FlowControlSettings flowControlSettings;
  private BatchingSettings batchingSettings;
  private RetrySettings retrySettings;
  private ExecutorProvider executorProvider;

  private final Long flowControlMaxOutstandingRequestBytes;
  private final Long flowControlMaxOutstandingElementCount;
  private final Long batchingElementCountThreshold;
  private final Long batchingRequestByteThreshold;
  private final Long batchingDelayThresholdMillis;
  private final Long retryInitialRetryDelayMillis;
  private final Double retryRetryDelayMultiplier;
  private final Long retryMaxRetryDelaySeconds;
  private final Long retryInitialRpcTimeoutSeconds;
  private final Double retryRpcTimeoutMultiplier;
  private final Long retryMaxRpcTimeoutSeconds;
  private final Long retryTotalTimeoutSeconds;
  private final Integer executorThreadCountMultiplier;

  public BigQueryToPubSubStreamerAbstract() {
    flowControlMaxOutstandingRequestBytes = 10 * 1024 * 1024L; // 10 MiB
    flowControlMaxOutstandingElementCount = 1000L;
    batchingElementCountThreshold = 100L; // default: 100 messages, max 1000
    batchingRequestByteThreshold = 1000000L;
    batchingDelayThresholdMillis = 1L; // default: 1 ms
    retryInitialRetryDelayMillis = 100L;
    retryRetryDelayMultiplier = 2.0;
    retryMaxRetryDelaySeconds = 60L;
    retryInitialRpcTimeoutSeconds = 1L;
    retryRpcTimeoutMultiplier = 1.0;
    retryMaxRpcTimeoutSeconds = 600L;
    retryTotalTimeoutSeconds = 600L;
    executorThreadCountMultiplier = 5;

    init();
  }

  public BigQueryToPubSubStreamerAbstract(
      Long flowControlMaxOutstandingRequestBytes,
      Long flowControlMaxOutstandingElementCount,
      Long batchingElementCountThreshold,
      Long batchingRequestByteThreshold,
      Long batchingDelayThresholdMillis,
      Long retryInitialRetryDelayMillis,
      Double retryRetryDelayMultiplier,
      Long retryMaxRetryDelaySeconds,
      Long retryInitialRpcTimeoutSeconds,
      Double retryRpcTimeoutMultiplier,
      Long retryMaxRpcTimeoutSeconds,
      Long retryTotalTimeoutSeconds,
      Integer executorThreadCountMultiplier) {

    this.flowControlMaxOutstandingRequestBytes = flowControlMaxOutstandingRequestBytes;
    this.flowControlMaxOutstandingElementCount = flowControlMaxOutstandingElementCount;
    this.batchingElementCountThreshold =
        batchingElementCountThreshold; // default: 100 messages, max 1000
    this.batchingRequestByteThreshold = batchingRequestByteThreshold;
    this.batchingDelayThresholdMillis = batchingDelayThresholdMillis;
    this.retryInitialRetryDelayMillis = retryInitialRetryDelayMillis;
    this.retryRetryDelayMultiplier = retryRetryDelayMultiplier;
    this.retryMaxRetryDelaySeconds = retryMaxRetryDelaySeconds;
    this.retryInitialRpcTimeoutSeconds = retryInitialRpcTimeoutSeconds;
    this.retryRpcTimeoutMultiplier = retryRpcTimeoutMultiplier;
    this.retryMaxRpcTimeoutSeconds = retryMaxRpcTimeoutSeconds;
    this.retryTotalTimeoutSeconds = retryTotalTimeoutSeconds;
    this.executorThreadCountMultiplier = executorThreadCountMultiplier;

    init();
  }

  public void init() {
    // Configure how many messages the publisher client can hold in memory
    // and what to do when messages exceed the limit.
    flowControlSettings =
        FlowControlSettings.newBuilder()
            // Block more messages from being published when the limit is reached. The other
            // options are Ignore (or continue publishing) and ThrowException (or error out).
            .setLimitExceededBehavior(FlowController.LimitExceededBehavior.Block)
            .setMaxOutstandingRequestBytes(this.flowControlMaxOutstandingRequestBytes)
            .setMaxOutstandingElementCount(this.flowControlMaxOutstandingElementCount)
            .build();

    // Configure batching settings
    batchingSettings =
        BatchingSettings.newBuilder()
            .setElementCountThreshold(this.batchingElementCountThreshold)
            .setRequestByteThreshold(this.batchingRequestByteThreshold)
            .setDelayThreshold(Duration.ofMillis(this.batchingDelayThresholdMillis))
            .setFlowControlSettings(flowControlSettings)
            .build();

    // Configure retry settings
    retrySettings =
        RetrySettings.newBuilder()
            .setInitialRetryDelay(Duration.ofMillis(this.retryInitialRetryDelayMillis))
            .setRetryDelayMultiplier(this.retryRetryDelayMultiplier)
            .setMaxRetryDelay(Duration.ofSeconds(this.retryMaxRetryDelaySeconds))
            .setInitialRpcTimeout(Duration.ofSeconds(this.retryInitialRpcTimeoutSeconds))
            .setRpcTimeoutMultiplier(this.retryRpcTimeoutMultiplier)
            .setMaxRpcTimeout(Duration.ofSeconds(this.retryMaxRpcTimeoutSeconds))
            .setTotalTimeout(Duration.ofSeconds(this.retryTotalTimeoutSeconds))
            .build();

    // Provides an executor service for processing messages. The default
    // `executorProvider` used by the publisher has a default thread count of
    // 5 * the number of processors available to the Java virtual machine.
    executorProvider =
        InstantiatingExecutorProvider.newBuilder()
            .setExecutorThreadCount(
                this.executorThreadCountMultiplier * Runtime.getRuntime().availableProcessors())
            .build();
  }

  private Publisher createPublisher(String projectId, String topicId) throws IOException {
    // Create a publisher instance with batching and retry settings
    return Publisher.newBuilder(TopicName.of(projectId, topicId))
        .setBatchingSettings(batchingSettings)
        .setRetrySettings(retrySettings)
        .setExecutorProvider(executorProvider)
        .build();
  }

  public FlowControlSettings getFlowControlSettings() {
    return flowControlSettings;
  }

  public BatchingSettings getBatchingSettings() {
    return batchingSettings;
  }

  public RetrySettings getRetrySettings() {
    return retrySettings;
  }

  public ExecutorProvider getExecutorProvider() {
    return executorProvider;
  }

  @Override
  public String toString() {
    return "BigQueryToPubSubStreamerAbstract{"
        + "flowControlSettings="
        + flowControlSettings
        + ", batchingSettings="
        + batchingSettings
        + ", retrySettings="
        + retrySettings
        + ", executorProvider="
        + executorProvider
        + ", flowControlMaxOutstandingRequestBytes="
        + flowControlMaxOutstandingRequestBytes
        + ", flowControlMaxOutstandingElementCount="
        + flowControlMaxOutstandingElementCount
        + ", batchingElementCountThreshold="
        + batchingElementCountThreshold
        + ", batchingRequestByteThreshold="
        + batchingRequestByteThreshold
        + ", batchingDelayThresholdMillis="
        + batchingDelayThresholdMillis
        + ", retryInitialRetryDelayMillis="
        + retryInitialRetryDelayMillis
        + ", retryRetryDelayMultiplier="
        + retryRetryDelayMultiplier
        + ", retryMaxRetryDelaySeconds="
        + retryMaxRetryDelaySeconds
        + ", retryInitialRpcTimeoutSeconds="
        + retryInitialRpcTimeoutSeconds
        + ", retryRpcTimeoutMultiplier="
        + retryRpcTimeoutMultiplier
        + ", retryMaxRpcTimeoutSeconds="
        + retryMaxRpcTimeoutSeconds
        + ", retryTotalTimeoutSeconds="
        + retryTotalTimeoutSeconds
        + ", executorThreadCountMultiplier="
        + executorThreadCountMultiplier
        + '}';
  }

  public void publishBigQueryTableResults(
      TableResult bqTableResults,
      String pubSubProjectId,
      String pubSubTopicId,
      String runId,
      LoggingHelper logger,
      long successMessagesIntervalForLogging)
      throws IOException,
          ExecutionException,
          InterruptedException,
          NonRetryableApplicationException {

    long startTimeMillis = System.currentTimeMillis();

    // Create a publisher instance with batching and retry settings
    Publisher publisher = createPublisher(pubSubProjectId, pubSubTopicId);

    // Publish each row to Pub/Sub and stream to BigQuery
    List<ApiFuture<String>> futures = new ArrayList<>();
    AtomicInteger bqRowsCounter = new AtomicInteger(0);
    AtomicInteger successfulPublishes = new AtomicInteger(0); // Counter for successful publishes
    AtomicInteger failedPublishes = new AtomicInteger(0);

    for (FieldValueList row : bqTableResults.iterateAll()) {
      bqRowsCounter.incrementAndGet();

      PubsubMessage pubsubMessage = bigQueryRowToPubSubMessage(row);

      ApiFuture<String> future = publisher.publish(pubsubMessage);

      // Add a callback to handle publish result and stream to BigQuery
      ApiFutures.addCallback(
          future,
          new ApiFutureCallback<>() {
            @Override
            public void onFailure(Throwable throwable) {
              failedPublishes.incrementAndGet();
              // System.err.println("Error publishing message: " + throwable.getMessage());
              // Handle error, e.g., log or store in an error table
              logger.logWarnWithTracker(
                  runId, runId, "Failed to publish PubSub message: " + throwable.getMessage());
            }

            @Override
            public void onSuccess(String messageId) {
              successfulPublishes.incrementAndGet();
              if (successfulPublishes.get() % successMessagesIntervalForLogging == 0) {
                long elapsedSeconds = (System.currentTimeMillis() - startTimeMillis) / 1000;
                logger.logInfoWithTracker(
                    runId,
                    runId,
                    String.format(
                        "PubSub successful messages count so far: %s after %s seconds ( %s mins)",
                        successfulPublishes.get(), elapsedSeconds, elapsedSeconds / 60));
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

    long endTimeMillis = System.currentTimeMillis();

    logger.logInfoWithTracker(
        runId,
        runId,
        String.format(
            "Total profiles fetched and processed from BigQuery : %s", bqRowsCounter.get()));

    logger.logInfoWithTracker(
        runId,
        runId,
        String.format("Total PubSub successful messages : %s", successfulPublishes.get()));

    logger.logInfoWithTracker(
        runId, runId, String.format("Total PubSub failed messages : %s", failedPublishes.get()));

    logger.logInfoWithTracker(
        runId,
        runId,
        String.format("Total duration in seconds : %s", (endTimeMillis - startTimeMillis) / 1000));
  }

  protected abstract PubsubMessage bigQueryRowToPubSubMessage(FieldValueList row)
      throws NonRetryableApplicationException;
}
