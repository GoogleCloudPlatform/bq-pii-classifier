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

import com.google.cloud.bigquery.FieldValue;
import com.google.cloud.bigquery.FieldValueList;
import com.google.cloud.oss.solutions.annotations.entities.DlpFieldFindings;
import com.google.cloud.oss.solutions.annotations.entities.DlpOtherInfoTypeMatch;
import com.google.cloud.oss.solutions.annotations.entities.TableSpec;
import com.google.cloud.oss.solutions.annotations.functions.tagger.TaggerRequest;
import com.google.protobuf.ByteString;
import com.google.pubsub.v1.PubsubMessage;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

/**
 * This class is a specialized implementation of {@link BigQueryToPubSubStreamerAbstract} designed
 * for processing BigQuery records that are intended for the BQ dispatcher. It includes specific
 * logic to convert BigQuery rows into {@link PubsubMessage} objects, which encapsulate {@link
 * TaggerRequest} data.
 */
public class BigQueryToPubSubStreamerForBQDispatcher extends BigQueryToPubSubStreamerAbstract {

  public BigQueryToPubSubStreamerForBQDispatcher() {
    super();
  }

  public BigQueryToPubSubStreamerForBQDispatcher(
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
   * The method extracts data from the row, constructs a {@link TaggerRequest}, and serializes it
   * into a JSON string before setting it as the message data.
   *
   * @param row The BigQuery row to convert.
   * @return A PubsubMessage containing the serialized TaggerRequest.
   */
  public PubsubMessage bigQueryRowToPubSubMessage(FieldValueList row) {

    String runId = row.get("run_id").getStringValue();
    String trackingId = row.get("tracking_id").getStringValue();
    String folderId = row.get("folder_id").getStringValue();
    String projectId = row.get("project_id").getStringValue();
    String datasetId = row.get("dataset_id").getStringValue();
    String tableId = row.get("table_id").getStringValue();
    List<FieldValue> fieldsStructValues = row.get("fields").getRepeatedValue(); // parse bq list

    Map<String, DlpFieldFindings> fieldsFindings = new HashMap<>();
    for (FieldValue struct1 : fieldsStructValues) {
      FieldValueList fieldsStruct = struct1.getRecordValue();
      // access struct fields by index and not by field name otherwise it fails
      String fieldName = fieldsStruct.get(0).getStringValue();
      String infoType = fieldsStruct.get(1).getStringValueOrDefault(null);

      List<FieldValue> otherMatchesStructValues = fieldsStruct.get(2).getRepeatedValue();
      List<DlpOtherInfoTypeMatch> otherMatches = new ArrayList<>();
      for (FieldValue struct2 : otherMatchesStructValues) {
        FieldValueList otherMatchesStruct = struct2.getRecordValue();
        String otherInfoType = otherMatchesStruct.get(0).getStringValue();
        Integer infoTypePrevalence = otherMatchesStruct.get(1).getNumericValue().intValue();
        otherMatches.add(new DlpOtherInfoTypeMatch(otherInfoType, infoTypePrevalence));
      }
      fieldsFindings.put(fieldName, new DlpFieldFindings(infoType, otherMatches));
    }

    TaggerRequest taggerRequest =
        new TaggerRequest(
            runId,
            trackingId,
            new TableSpec(folderId, projectId, datasetId, tableId),
            fieldsFindings);

    ByteString data = ByteString.copyFromUtf8(taggerRequest.toJsonString());

    return PubsubMessage.newBuilder().setData(data).build();
  }
}
