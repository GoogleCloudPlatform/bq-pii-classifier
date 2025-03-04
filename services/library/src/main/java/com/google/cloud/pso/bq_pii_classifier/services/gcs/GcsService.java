package com.google.cloud.pso.bq_pii_classifier.services.gcs;

import com.google.cloud.pso.bq_pii_classifier.entities.NonRetryableApplicationException;
import com.google.cloud.pso.bq_pii_classifier.entities.ResourceLabelingAction;

import java.util.Map;

public interface GcsService {

    /**
     *
     * @param bucketName the bucket to be updated
     * @param newLabels the map of labels to be attached to the bucket
     * @param existingLabelsRegex a regex to match existing bucket labels to be deleted before adding the new labels
     * @throws NonRetryableApplicationException
     * @return the final map of labels that is attached to the bucket
     */
    Map<Map.Entry<String, String>, ResourceLabelingAction> mergeLabelsToBucket(String bucketName,
                                                                               Map<String, String> newLabels,
                                                                               String existingLabelsRegex,
                                                                               boolean isDryRun) throws NonRetryableApplicationException;
}
