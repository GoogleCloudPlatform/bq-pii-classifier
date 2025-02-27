package com.google.cloud.pso.bq_pii_classifier.services.pubsub;

import com.google.cloud.bigquery.FieldValueList;
import com.google.cloud.pso.bq_pii_classifier.entities.GcsDlpProfileSummary;
import com.google.cloud.pso.bq_pii_classifier.entities.NonRetryableApplicationException;
import com.google.cloud.pso.bq_pii_classifier.functions.tagger.TaggerTableSpecRequest;
import com.google.cloud.pso.bq_pii_classifier.functions.tagger.gcs.GcsTaggerRequest;
import com.google.cloud.pso.bq_pii_classifier.helpers.TrackingHelper;
import com.google.cloud.pso.bq_pii_classifier.helpers.Utils;
import com.google.protobuf.ByteString;
import com.google.pubsub.v1.PubsubMessage;
import java.util.HashSet;

public class PubSubServiceImplForBigQueryDispatcher extends PubSubServiceImplAbstract{
    public PubsubMessage bigQueryRowToPubSubMessage(FieldValueList row, String runId) throws NonRetryableApplicationException {
        throw new NonRetryableApplicationException("Method not implement");
        }

}
