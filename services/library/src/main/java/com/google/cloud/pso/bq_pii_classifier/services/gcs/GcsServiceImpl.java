package com.google.cloud.pso.bq_pii_classifier.services.gcs;

import com.google.cloud.pso.bq_pii_classifier.entities.NonRetryableApplicationException;
import com.google.cloud.pso.bq_pii_classifier.entities.ResourceLabelingAction;
import com.google.cloud.pso.bq_pii_classifier.helpers.LabelsHelper;
import com.google.cloud.storage.Bucket;
import com.google.cloud.storage.Storage;
import com.google.cloud.storage.StorageOptions;

import java.util.HashMap;
import java.util.Map;
import java.util.regex.Pattern;

public class GcsServiceImpl implements GcsService {

  private final Storage storage;

  public GcsServiceImpl() {
    this.storage = StorageOptions.newBuilder().build().getService();
    ;
  }

  public Map<Map.Entry<String, String>, ResourceLabelingAction> mergeLabelsToBucket(String bucketName,
                                                                                    Map<String, String> newLabels,
                                                                                    String existingLabelsRegex,
                                                                                    boolean isDryRun) throws NonRetryableApplicationException {

    if (newLabels == null || newLabels.isEmpty()){
     return new HashMap<>();
    }

    Bucket bucket = storage.get(bucketName);

    if (bucket == null) {
      throw new NonRetryableApplicationException(String.format("Bucket %s not found.", bucketName));
    }

    // create a mutable map for existing bucket labels
    Map<String, String> bucketLabels;
    if (bucket.getLabels() == null){
      bucketLabels = new HashMap<>();
    }else{
      bucketLabels = new HashMap<>(bucket.getLabels());
    }

    Map<Map.Entry<String, String>, ResourceLabelingAction> finalLabelsWithActions = LabelsHelper.computeLabelsActions(bucketLabels, newLabels, existingLabelsRegex);

    Map<String, String> labelsToAttach = LabelsHelper.removeToBeDeletedLabels(finalLabelsWithActions);

    if (!isDryRun){
      Bucket updatedBucket = bucket.toBuilder().setLabels(labelsToAttach).build();
      storage.update(updatedBucket);
    }

    return finalLabelsWithActions;
  }
}
