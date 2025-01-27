package com.google.cloud.pso.bq_pii_classifier.services.gcs;

import com.google.cloud.pso.bq_pii_classifier.entities.NonRetryableApplicationException;
import com.google.cloud.storage.Bucket;
import com.google.cloud.storage.Storage;
import com.google.cloud.storage.StorageOptions;

import java.io.IOException;
import java.util.Map;

public class GcsServiceImpl implements GcsService {

    private final Storage storage;

    public GcsServiceImpl() {
        this.storage = StorageOptions.newBuilder().build().getService();;
    }

    @Override
    public void addLabelsToBucket(String bucketName, Map<String, String> labels) throws NonRetryableApplicationException {

        Bucket bucket = storage.get(bucketName);

        if (bucket == null) {
            throw new NonRetryableApplicationException(String.format("Bucket %s not found.", bucketName));
        }

        Bucket updatedBucket = bucket.toBuilder().setLabels(labels).build();
        storage.update(updatedBucket);
    }
}
