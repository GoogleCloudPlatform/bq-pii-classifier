package com.google.cloud.pso.bq_pii_classifier.services.gcs;

import com.google.cloud.pso.bq_pii_classifier.entities.NonRetryableApplicationException;
import com.google.cloud.pso.bq_pii_classifier.entities.ResourceLabelingAction;
import com.google.cloud.storage.Bucket;
import com.google.cloud.storage.Storage;
import com.google.cloud.storage.StorageOptions;

import java.io.IOException;
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

    Map<Map.Entry<String, String>, ResourceLabelingAction> finalLabelsWithActions = computeLabelsActions(bucketLabels, newLabels, existingLabelsRegex);

    Map<String, String> labelsToAttach = filterLabelsToAdd(finalLabelsWithActions);

    if (!isDryRun){
      Bucket updatedBucket = bucket.toBuilder().setLabels(labelsToAttach).build();
      storage.update(updatedBucket);
    }

    return finalLabelsWithActions;
  }

  public static Map<Map.Entry<String, String>, ResourceLabelingAction> computeLabelsActions(Map<String, String> bucketLabels, Map<String, String> newLabels, String existingLabelsRegex){

    Pattern pattern = Pattern.compile(existingLabelsRegex);

    Map<Map.Entry<String, String>, ResourceLabelingAction> finalLabelsWithAction = new HashMap<>();

    // compare new labels to existing ones
    for(Map.Entry<String, String> newLabel: newLabels.entrySet()){
      if(!bucketLabels.containsKey(newLabel.getKey())){
        // key-value pair is new
        finalLabelsWithAction.put(newLabel, ResourceLabelingAction.NEW_KEY);
      }else{
        // key already exists
        // check if value has changed
        if (newLabel.getValue().equals( bucketLabels.get(newLabel.getKey()))){
          finalLabelsWithAction.put(newLabel, ResourceLabelingAction.NO_CHANGE);
        }else{
          finalLabelsWithAction.put(newLabel, ResourceLabelingAction.NEW_VALUE);
        }
      }
    }

    // check existing labels if they need to be removed
    for(Map.Entry<String, String> label: bucketLabels.entrySet()){
      // if existing key matches the regex for labels to be removed AND it's not in the new labels, then it should be removed
      if(pattern.matcher(label.getKey()).find() && !newLabels.containsKey(label.getKey())){
        // if the label matches the regex, it should be deleted
        finalLabelsWithAction.put(label, ResourceLabelingAction.DELETE);
      }else{
        // if the existing label doesn't exist in the new labels (but not matching the removal regex), then keep it
        if(!newLabels.containsKey(label.getKey())){
          finalLabelsWithAction.put(label, ResourceLabelingAction.NO_CHANGE);
        }
      }
    }

    return finalLabelsWithAction;
  }

  public static Map<String, String> filterLabelsToAdd(Map<Map.Entry<String, String>, ResourceLabelingAction> labelsWithAction){
    Map<String, String> finalLabels = new HashMap<>();

    for(Map.Entry<Map.Entry<String, String>, ResourceLabelingAction> labelWithAction : labelsWithAction.entrySet()){

      if (!labelWithAction.getValue().equals(ResourceLabelingAction.DELETE)){
        finalLabels.put(labelWithAction.getKey().getKey(), labelWithAction.getKey().getValue());
      }
    }
    return finalLabels;
  }
}
