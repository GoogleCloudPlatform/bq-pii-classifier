package com.google.cloud.pso.bq_pii_classifier.services.gcs;

import com.google.cloud.pso.bq_pii_classifier.entities.NonRetryableApplicationException;

import java.io.IOException;
import java.util.Map;

public interface GcsService {

    void addLabelsToBucket(String bucketName, Map<String, String> labels) throws IOException, NonRetryableApplicationException;
}
