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
import com.google.cloud.oss.solutions.annotations.entities.TableSpec;
import com.google.cloud.oss.solutions.annotations.functions.cleaner.BigQueryTableAnnotationsCleanerRequest;
import com.google.protobuf.ByteString;
import com.google.pubsub.v1.PubsubMessage;


/**
 * This class is a specialized implementation of {@link BigQueryToPubSubStreamerAbstract} designed
 * for processing BigQuery records that are intended for the BigQuery tables tags cleaner dispatcher. It includes specific
 * logic to convert BigQuery rows into {@link PubsubMessage} objects, which encapsulate {@link
 * BigQueryTableAnnotationsCleanerRequest} data.
 */
public class BigQueryToPubSubStreamerForBQCleaningDispatcher extends BigQueryToPubSubStreamerAbstract {

  public BigQueryToPubSubStreamerForBQCleaningDispatcher() {
    super();
  }

  public BigQueryToPubSubStreamerForBQCleaningDispatcher(
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
   * The method extracts data from the row, constructs a {@link BigQueryTableAnnotationsCleanerRequest}, and serializes it
   * into a JSON string before setting it as the message data.
   *
   * @param row The BigQuery row to convert.
   * @return A PubsubMessage containing the serialized {@link BigQueryTableAnnotationsCleanerRequest}.
   */
  public PubsubMessage bigQueryRowToPubSubMessage(FieldValueList row) {

    String runId = row.get("run_id").getStringValue();
    String trackingId = row.get("tracking_id").getStringValue();
    String folder_id = row.get("folder_id").isNull()? "" : row.get("folder_id").getStringValue();
    String projectId = row.get("project_id").getStringValue();
    String datasetId = row.get("dataset_id").getStringValue();
    String tableId = row.get("table_id").getStringValue();
    String tableRegion = row.get("table_region").getStringValue();
    String tagValue = row.get("tag_value").getStringValue();

    BigQueryTableAnnotationsCleanerRequest request = new BigQueryTableAnnotationsCleanerRequest(runId,
            trackingId, new TableSpec(folder_id, projectId, datasetId, tableId), tableRegion, tagValue);

    ByteString data = ByteString.copyFromUtf8(request.toJsonString());

    return PubsubMessage.newBuilder().setData(data).build();
  }
}
