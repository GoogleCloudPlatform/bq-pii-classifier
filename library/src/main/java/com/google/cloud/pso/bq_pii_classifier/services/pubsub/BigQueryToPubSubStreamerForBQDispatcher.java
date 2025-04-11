package com.google.cloud.pso.bq_pii_classifier.services.pubsub;

import com.google.cloud.bigquery.FieldValue;
import com.google.cloud.bigquery.FieldValueList;
import com.google.cloud.pso.bq_pii_classifier.entities.DlpFieldFindings;
import com.google.cloud.pso.bq_pii_classifier.entities.DlpOtherInfoTypeMatch;
import com.google.cloud.pso.bq_pii_classifier.entities.TableSpec;
import com.google.cloud.pso.bq_pii_classifier.functions.tagger.TaggerRequest;
import com.google.protobuf.ByteString;
import com.google.pubsub.v1.PubsubMessage;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

public class BigQueryToPubSubStreamerForBQDispatcher extends BigQueryToPubSubStreamerAbstract {

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
