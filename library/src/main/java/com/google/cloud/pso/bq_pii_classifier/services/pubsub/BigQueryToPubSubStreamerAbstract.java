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

package com.google.cloud.pso.bq_pii_classifier.services.pubsub;


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
import com.google.cloud.pso.bq_pii_classifier.entities.NonRetryableApplicationException;
import com.google.cloud.pso.bq_pii_classifier.helpers.LoggingHelper;
import com.google.cloud.pubsub.v1.Publisher;
import com.google.pubsub.v1.PubsubMessage;
import com.google.pubsub.v1.TopicName;
import org.threeten.bp.Duration;

import java.io.IOException;
import java.util.ArrayList;
import java.util.List;
import java.util.concurrent.ExecutionException;
import java.util.concurrent.TimeUnit;
import java.util.concurrent.atomic.AtomicInteger;

public abstract class BigQueryToPubSubStreamerAbstract implements BigQueryToPubSubStreamer {

    private final FlowControlSettings flowControlSettings;
    private final BatchingSettings batchingSettings;
    private final RetrySettings retrySettings;

    private final ExecutorProvider executorProvider;

    public BigQueryToPubSubStreamerAbstract(){
        // Configure how many messages the publisher client can hold in memory
        // and what to do when messages exceed the limit.
        flowControlSettings =
                FlowControlSettings.newBuilder()
                        // Block more messages from being published when the limit is reached. The other
                        // options are Ignore (or continue publishing) and ThrowException (or error out).
                        .setLimitExceededBehavior(FlowController.LimitExceededBehavior.Block)
                        .setMaxOutstandingRequestBytes(10 * 1024 * 1024L) // 10 MiB
                        .setMaxOutstandingElementCount(1000L) // 100 messages
                        .build();

        // Configure batching settings
        batchingSettings = BatchingSettings.newBuilder()
                .setElementCountThreshold(100L) // default: 100 messages, max 1000
                .setRequestByteThreshold(1000000L) // default: 1000 bytes // max 10mb this makes it faster
                .setDelayThreshold(Duration.ofMillis(1)) // default: 1 ms
                .setFlowControlSettings(flowControlSettings)
                .build();


        // Configure retry settings
        retrySettings = RetrySettings.newBuilder()
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
        executorProvider =
                InstantiatingExecutorProvider.newBuilder()
                        .setExecutorThreadCount(5 * Runtime.getRuntime().availableProcessors())
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

        long startTimeMilis = System.currentTimeMillis();


      // Create a publisher instance with batching and retry settings
      Publisher publisher = createPublisher(pubSubProjectId, pubSubTopicId);

        // Publish each row to Pub/Sub and stream to BigQuery
        List<ApiFuture<String>> futures = new ArrayList<>();
        AtomicInteger bqRowsCounter = new AtomicInteger(0);
        AtomicInteger successfulPublishes = new AtomicInteger(0); // Counter for successful publishes
        AtomicInteger failedPublishes = new AtomicInteger(0);

        for (FieldValueList row: bqTableResults.iterateAll()) {
            bqRowsCounter.incrementAndGet();

            PubsubMessage pubsubMessage = bigQueryRowToPubSubMessage(row);

            ApiFuture<String> future = publisher.publish(pubsubMessage);

            // Add a callback to handle publish result and stream to BigQuery
            ApiFutures.addCallback(future, new ApiFutureCallback<>() {
                @Override
                public void onFailure(Throwable throwable) {
                    failedPublishes.incrementAndGet();
                    //System.err.println("Error publishing message: " + throwable.getMessage());
                    // Handle error, e.g., log or store in an error table
                    logger.logWarnWithTracker(runId, runId, "Failed to publish PubSub message: "+ throwable.getMessage());
                }

                @Override
                public void onSuccess(String messageId) {
                    successfulPublishes.incrementAndGet();
                    if(successfulPublishes.get() % successMessagesIntervalForLogging == 0){
                        long elapsedSeconds = (System.currentTimeMillis() - startTimeMilis) / 1000;
                        logger.logInfoWithTracker(runId,
                                runId,
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
                runId,
                String.format("Total profiles fetched and processed from BigQuery : %s", bqRowsCounter.get()));

        logger.logInfoWithTracker(runId,
                runId,
                String.format("Total PubSub successful messages : %s", successfulPublishes.get()));

        logger.logInfoWithTracker(runId,
                runId,
                String.format("Total PubSub failed messages : %s", failedPublishes.get()));

        logger.logInfoWithTracker(runId,
                runId,
                String.format("Total duration in seconds : %s", (endTimeMilis-startTimeMilis)/1000));
    }

    protected abstract PubsubMessage bigQueryRowToPubSubMessage(FieldValueList row) throws NonRetryableApplicationException;
}
