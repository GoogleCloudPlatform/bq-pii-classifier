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
import com.google.cloud.pso.bq_pii_classifier.helpers.LoggingHelper;
import com.google.cloud.pso.bq_pii_classifier.helpers.TrackingHelper;
import com.google.cloud.pubsub.v1.Publisher;
import com.google.protobuf.ByteString;
import com.google.pubsub.v1.PubsubMessage;
import com.google.pubsub.v1.TopicName;
import org.threeten.bp.Duration;

import java.io.IOException;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.List;
import java.util.concurrent.ExecutionException;
import java.util.concurrent.TimeUnit;
import java.util.concurrent.atomic.AtomicInteger;

public class PubSubStressTesting {
    public static void main(String [] args) throws InterruptedException, ExecutionException, IOException {

        String testVariable = System.getenv().getOrDefault("TEST_VARIABLE", "DEFAULT");
        System.out.println("TEST VARIABLE = "+ testVariable);

        String projectId = "bqsc-host-v1";

        // Replace with your Pub/Sub topic ID
        String topicId = "dataflow-test";

        LoggingHelper logger = new LoggingHelper(PubSubStressTesting.class.getSimpleName(), 1, projectId);
        String runId = TrackingHelper.generateTaggingRunId();


        System.out.println("Args: "+ Arrays.toString(args));
        logger.logInfoWithTracker(runId, "Args: "+ Arrays.toString(args));

        int queryArrayLen = args != null && args.length >= 1? Integer.parseInt(args[0]): 1000;
        int queryLimit = args != null && args.length >= 2? Integer.parseInt(args[1]): 10;
        int threadsFactor = args != null && args.length >= 3? Integer.parseInt(args[2]): 5;
        long batchElementCountThreshold = args != null && args.length >= 4? Long.parseLong(args[3]): 100L;
        long batchRequestByteThreshold = args != null && args.length >= 5? Long.parseLong(args[4]): 1000000L;
        long batchDelayThresholdMilis = args != null && args.length >= 6? Long.parseLong(args[5]): 1L;

        System.out.printf("Will use params queryArrayLen = %s,  = queryLimit = %s, threadsFactor = %s, batchElementCountThreshold = %s, batchRequestByteThreshold = %s, batchDelayThresholdMilis = %s%n",
                queryArrayLen,
                queryLimit,
                threadsFactor,
                batchElementCountThreshold,
                batchRequestByteThreshold,
                batchDelayThresholdMilis
        );
        logger.logInfoWithTracker(runId, String.format("Will use params queryArrayLen = %s,  = queryLimit = %s, threadsFactor = %s, batchElementCountThreshold = %s, batchRequestByteThreshold = %s, batchDelayThresholdMilis = %s%n",
                queryArrayLen,
                queryLimit,
                threadsFactor,
                batchElementCountThreshold,
                batchRequestByteThreshold,
                batchDelayThresholdMilis
        ));

        System.out.println("Available Processors "+ Runtime.getRuntime().availableProcessors());
        logger.logInfoWithTracker(runId, "Available Processors "+ Runtime.getRuntime().availableProcessors());

        long startTimeMilis = System.currentTimeMillis();
        // Replace with your Google Cloud project ID


        // Instantiate a BigQuery client
        BigQuery bigquery = BigQueryOptions.newBuilder()
                .setProjectId(projectId)
                .setLocation("eu")
                .build()
                .getService();


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
                .setElementCountThreshold(batchElementCountThreshold) // default: 100 messages, max 1000
                .setRequestByteThreshold(batchRequestByteThreshold) // default: 1000 bytes // max 10mb this makes it faster
                .setDelayThreshold(Duration.ofMillis(batchDelayThresholdMilis)) // default: 1 ms
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
                        .setExecutorThreadCount(threadsFactor * Runtime.getRuntime().availableProcessors())
                        .build();

        // Create a publisher instance with batching and retry settings
        Publisher publisher = Publisher.newBuilder(TopicName.of(projectId, topicId))
                .setBatchingSettings(batchingSettings)
                .setRetrySettings(retrySettings)
                .setExecutorProvider(executorProvider)
                .build();

        // BigQuery query to execute
        String query =
                "\n"
                        + "WITH a AS (\n"
                        + "    SELECT\n"
                        + "        SUBSTRING(file_store_profile.file_store_path,6) AS bucket_name,\n"
                        + "        file_store_profile.project_id AS project_id,\n"
                        + "        ARRAY_TO_STRING(ARRAY_AGG(DISTINCT ss.info_type.name), ',') AS info_types\n"
                        + "    FROM `bqsc-host-v1.bq_pii_classifier.dlp_discovery_services_gcs_results_latest_v1`,\n"
                        + "        UNNEST(file_store_profile.file_cluster_summaries) s,\n"
                        + "        UNNEST(s.file_store_info_type_summaries) ss\n"
                        + "    WHERE\n"
                        + "        REGEXP_CONTAINS(file_store_profile.project_id, r'.*') AND  \n"
                        + "        REGEXP_CONTAINS(SUBSTRING(file_store_profile.file_store_path,6), r'.*')\n"
                        + "    GROUP BY 1,2\n"
                        + "    HAVING \n"
                        + "        ARRAY_LENGTH(ARRAY_AGG(DISTINCT ss.info_type.name)) > 0\n"
                        + ")\n"
                        + "\n"
                        + "SELECT\n"
                        + "    '1740422835101-T' AS run_id,\n"
                        + "    CONCAT('1740422835101-T', '-', GENERATE_UUID()) AS tracking_id,\n"
                        + "    a.bucket_name,\n"
                        + "    a.project_id,\n"
                        + "    a.info_types\n"
                        + "FROM a\n"
                        + "CROSS JOIN (SELECT num AS number FROM UNNEST(GENERATE_ARRAY(1, "+ queryArrayLen +")) AS num) AS s\n"
                        + "LIMIT "+queryLimit + " ;\n";

        // Configure the query job
        QueryJobConfiguration queryConfig = QueryJobConfiguration.newBuilder(query)
                .setUseQueryCache(true)
                .setAllowLargeResults(true)
                .build();

        // Execute the query
        System.out.println("Running BQ query .. ");
        logger.logInfoWithTracker(runId, "Running BQ query .. ");

        Job queryJob = bigquery.create(JobInfo.of(queryConfig));
        queryJob = queryJob.waitFor();

        // Check for errors
        if (queryJob == null) {
            throw new RuntimeException("Job no longer exists");
        } else if (queryJob.getStatus().getError()!= null) {
            throw new RuntimeException(queryJob.getStatus().getError().toString());
        }

        // Get the results
        TableResult result = queryJob.getQueryResults();

        System.out.println("BQ results rows  " + result.getTotalRows());
        logger.logInfoWithTracker(runId, "BQ results rows  " + result.getTotalRows());

        // Publish each row to Pub/Sub and stream to BigQuery
        List<ApiFuture<String>> futures = new ArrayList<>();
        AtomicInteger bqRowsCounter = new AtomicInteger(0);
        AtomicInteger successfulPublishes = new AtomicInteger(0); // Counter for successful publishes
        AtomicInteger failedPublishes = new AtomicInteger(0);

        for (FieldValueList row: result.iterateAll()) {
            bqRowsCounter.incrementAndGet();
            String message = row.toString(); // Convert row to JSON string
            ByteString data = ByteString.copyFromUtf8(message);
            ApiFuture<String> future = publisher.publish(PubsubMessage.newBuilder().setData(data).build());

            // Add a callback to handle publish result and stream to BigQuery
            ApiFutures.addCallback(future, new ApiFutureCallback<>() {
                @Override
                public void onFailure(Throwable throwable) {
                    failedPublishes.incrementAndGet();
                    //System.err.println("Error publishing message: " + throwable.getMessage());
                    // Handle error, e.g., log or store in an error table
                }

                @Override
                public void onSuccess(String messageId) {
                    successfulPublishes.incrementAndGet();
                    if(successfulPublishes.get() % 1000000 == 0){
                        long elapsedSeconds = (System.currentTimeMillis() - startTimeMilis) / 1000;
                        String msg = String.format("PubSub successful messages count so far: %s after %s seconds ( %s mins)%n%n",
                                successfulPublishes.get(),
                                elapsedSeconds,
                                elapsedSeconds/60);
                        System.out.println(msg);
                        logger.logInfoWithTracker(runId, msg);
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

        System.out.println("BQ records a total of " + bqRowsCounter.get());
        System.out.println("Published a total of " + successfulPublishes.get() + " messages to Pub/Sub.");
        System.out.println("Failed to publish a total of " + failedPublishes.get() + " messages to Pub/Sub.");
        System.out.println("Duration in seconds "+ (endTimeMilis-startTimeMilis)/1000);

        logger.logInfoWithTracker(runId, "BQ records a total of " + bqRowsCounter.get());
        logger.logInfoWithTracker(runId, "Published a total of " + successfulPublishes.get() + " messages to Pub/Sub.");
        logger.logInfoWithTracker(runId, "Failed to publish a total of " + failedPublishes.get() + " messages to Pub/Sub.");
        logger.logInfoWithTracker(runId, "Duration in seconds "+ (endTimeMilis-startTimeMilis)/1000);
    }
}
