package com.google.cloud.pso.bq_pii_classifier.services.pubsub;

import com.google.cloud.bigquery.FieldValueList;
import com.google.cloud.pso.bq_pii_classifier.entities.GcsDlpProfileSummary;
import com.google.cloud.pso.bq_pii_classifier.functions.tagger.gcs.GcsTaggerRequest;
import com.google.cloud.pso.bq_pii_classifier.helpers.Utils;
import com.google.protobuf.ByteString;
import com.google.pubsub.v1.PubsubMessage;

import java.util.HashSet;

public class BigQueryToPubSubStreamerForGcsDispatcher extends BigQueryToPubSubStreamerAbstract {
    public PubsubMessage bigQueryRowToPubSubMessage(FieldValueList row){
        String runId = row.get("run_id").getStringValue();
        String trackingId = row.get("tracking_id").getStringValue();
        String bucketName = row.get("bucket_name").getStringValue();
        String projectId = row.get("project_id").getStringValue();
        String infoTypesStrList = row.get("info_types").getStringValue();


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

        return PubsubMessage.newBuilder()
                .setData(data)
                .build();
    }
}
