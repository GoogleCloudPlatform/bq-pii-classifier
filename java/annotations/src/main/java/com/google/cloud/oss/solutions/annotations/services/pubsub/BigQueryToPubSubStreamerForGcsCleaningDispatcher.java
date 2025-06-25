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

import com.google.cloud.bigquery.FieldValueList;
import com.google.cloud.oss.solutions.annotations.functions.cleaner.GcsBucketAnnotationsCleanerRequest;
import com.google.protobuf.ByteString;
import com.google.pubsub.v1.PubsubMessage;


/**
 * This class is a specialized implementation of {@link BigQueryToPubSubStreamerAbstract} designed
 * for processing BigQuery records that are intended for the Gcs buckets tags cleaner dispatcher. It includes specific
 * logic to convert BigQuery rows into {@link PubsubMessage} objects, which encapsulate {@link
 * GcsBucketAnnotationsCleanerRequest} data.
 */
public class BigQueryToPubSubStreamerForGcsCleaningDispatcher extends BigQueryToPubSubStreamerAbstract {

  public BigQueryToPubSubStreamerForGcsCleaningDispatcher() {
    super();
  }

  public BigQueryToPubSubStreamerForGcsCleaningDispatcher(
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
    super(
        flowControlMaxOutstandingRequestBytes,
        flowControlMaxOutstandingElementCount,
        batchingElementCountThreshold,
        batchingRequestByteThreshold,
        batchingDelayThresholdMillis,
        retryInitialRetryDelayMillis,
        retryRetryDelayMultiplier,
        retryMaxRetryDelaySeconds,
        retryInitialRpcTimeoutSeconds,
        retryRpcTimeoutMultiplier,
        retryMaxRpcTimeoutSeconds,
        retryTotalTimeoutSeconds,
        executorThreadCountMultiplier);
  }

  /**
   * Converts a BigQuery row (represented as a {@link FieldValueList}) into a {@link PubsubMessage}.
   * The method extracts data from the row, constructs a {@link GcsBucketAnnotationsCleanerRequest}, and serializes it
   * into a JSON string before setting it as the message data.
   *
   * @param row The BigQuery row to convert.
   * @return A PubsubMessage containing the serialized {@link GcsBucketAnnotationsCleanerRequest}.
   */
  public PubsubMessage bigQueryRowToPubSubMessage(FieldValueList row) {

    String runId = row.get("run_id").getStringValue();
    String trackingId = row.get("tracking_id").getStringValue();
    String projectId = row.get("project_id").getStringValue();
    String bucketName = row.get("bucket_name").getStringValue();
    String bucketLocation = row.get("bucket_location").getStringValue();
    String tagValue = row.get("tag_value").getStringValue();

    GcsBucketAnnotationsCleanerRequest request = new GcsBucketAnnotationsCleanerRequest(runId,
            trackingId, projectId, bucketName, bucketLocation, tagValue);

    ByteString data = ByteString.copyFromUtf8(request.toJsonString());

    return PubsubMessage.newBuilder().setData(data).build();
  }
}
