package com.google.cloud.pso.bq_pii_classifier.services.pubsub;

import com.google.cloud.bigquery.FieldValue;
import com.google.cloud.bigquery.FieldValueList;
import com.google.cloud.pso.bq_pii_classifier.entities.TableSpec;
import com.google.cloud.pso.bq_pii_classifier.functions.tagger.TaggerRequest;
import com.google.cloud.pso.bq_pii_classifier.entities.PolicyTagInfo;
import com.google.cloud.pso.bq_pii_classifier.entities.TablePolicyTags;
import com.google.protobuf.ByteString;
import com.google.pubsub.v1.PubsubMessage;

import java.util.HashMap;
import java.util.List;
import java.util.Map;

public class PubSubServiceImplForBigQueryDispatcher extends PubSubServiceImplAbstract{

    public PubsubMessage bigQueryRowToPubSubMessage(FieldValueList row){

        String runId = row.get("run_id").getStringValue();
        String trackingId = row.get("tracking_id").getStringValue();
        String projectId = row.get("project_id").getStringValue();
        String datasetId = row.get("dataset_id").getStringValue();
        String tableId = row.get("table_id").getStringValue();
        List<FieldValue> fieldsStructValues = row.get("fields").getRepeatedValue(); // parse bq list

        Map<String, PolicyTagInfo> fieldsPolicyTags = new HashMap<>();
        for (FieldValue struct: fieldsStructValues){
            FieldValueList structValues = struct.getRecordValue();
            // access struct fields by index and not by field name otherwise it fails
            String fieldName = structValues.get(0).getStringValue();
            String infoType = structValues.get(1).getStringValue();
            String policyTag = structValues.get(2).getStringValue();
            String classification = structValues.get(3).getStringValue();

            fieldsPolicyTags.put(fieldName, new PolicyTagInfo(
                    infoType,
                    policyTag,
                    classification
            ));
        }

        TaggerRequest taggerRequest = new TaggerRequest(
                runId,
                trackingId,
                new TablePolicyTags(
                        new TableSpec(projectId, datasetId, tableId),
                        fieldsPolicyTags
                )
        );

        ByteString data = ByteString.copyFromUtf8(taggerRequest.toJsonString());

        return PubsubMessage.newBuilder()
                .setData(data)
                .build();
    }

}
