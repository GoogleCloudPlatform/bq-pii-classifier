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
import com.google.cloud.oss.solutions.annotations.entities.GcsDlpProfileSummary;
import com.google.cloud.oss.solutions.annotations.functions.tagger.gcs.GcsTaggerRequest;
import com.google.cloud.oss.solutions.annotations.helpers.Utils;
import com.google.protobuf.ByteString;
import com.google.pubsub.v1.PubsubMessage;
import java.util.HashSet;

/**
 * Concrete implementation of {@link BigQueryToPubSubStreamerAbstract} for dispatching GCS related
 * messages.
 */
public class BigQueryToPubSubStreamerForGcsDispatcher extends BigQueryToPubSubStreamerAbstract {

  public BigQueryToPubSubStreamerForGcsDispatcher() {
    super();
  }

  public BigQueryToPubSubStreamerForGcsDispatcher(
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

  @Override
  public PubsubMessage bigQueryRowToPubSubMessage(FieldValueList row) {
    String runId = row.get("run_id").getStringValue();
    String trackingId = row.get("tracking_id").getStringValue();
    String profileName = row.get("profile_name").getStringValue();
    String bucketName = row.get("bucket_name").getStringValue();
    String projectId = row.get("project_id").getStringValue();
    String folderId = row.get("folder_id").getStringValue();
    String infoTypesStrList = row.get("info_types").getStringValue();

    GcsTaggerRequest taggerRequest =
        new GcsTaggerRequest(
            runId,
            trackingId,
            new GcsDlpProfileSummary(
                profileName,
                String.format("gs://%s", bucketName),
                projectId,
                folderId,
                new HashSet<>(Utils.tokenize(infoTypesStrList, ",", true))));

    ByteString data = ByteString.copyFromUtf8(taggerRequest.toJsonString());

    return PubsubMessage.newBuilder().setData(data).build();
  }
}
