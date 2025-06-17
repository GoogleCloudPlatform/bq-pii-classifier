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

package com.google.cloud.oss.solutions.annotations.helpers;

import com.google.cloud.oss.solutions.annotations.entities.ResourceLabelingAction;
import java.util.HashMap;
import java.util.Map;
import java.util.regex.Pattern;

/** Helper class to compute actions to be performed on labels. */
public class LabelsHelper {

  /**
   * Compute the actions to be performed on labels.
   *
   * @param existingLabels existing labels on the resource.
   * @param newLabels new labels to be applied on the resource.
   * @param existingLabelsRegex regex to identify labels that should be removed.
   * @return a map of labels with the action to be performed.
   */
  public static Map<Map.Entry<String, String>, ResourceLabelingAction> computeLabelsActions(
      Map<String, String> existingLabels,
      Map<String, String> newLabels,
      String existingLabelsRegex) {

    if (existingLabels == null) {
      existingLabels = new HashMap<>();
    }
    if (newLabels == null) {
      newLabels = new HashMap<>();
    }

    Pattern pattern = Pattern.compile(existingLabelsRegex);

    Map<Map.Entry<String, String>, ResourceLabelingAction> finalLabelsWithAction = new HashMap<>();

    // compare new labels to existing ones
    for (Map.Entry<String, String> newLabel : newLabels.entrySet()) {
      if (!existingLabels.containsKey(newLabel.getKey())) {
        // key-value pair is new
        finalLabelsWithAction.put(newLabel, ResourceLabelingAction.NEW_KEY);
      } else {
        // key already exists
        // check if value has changed
        if (newLabel.getValue().equals(existingLabels.get(newLabel.getKey()))) {
          finalLabelsWithAction.put(newLabel, ResourceLabelingAction.NO_CHANGE);
        } else {
          finalLabelsWithAction.put(newLabel, ResourceLabelingAction.NEW_VALUE);
        }
      }
    }

    // check existing labels if they need to be removed
    for (Map.Entry<String, String> label : existingLabels.entrySet()) {
      // if existing key matches the regex for labels to be removed AND it's not in the new labels,
      // then it should be removed
      if (pattern.matcher(label.getKey()).find() && !newLabels.containsKey(label.getKey())) {
        // if the label matches the regex, it should be deleted
        finalLabelsWithAction.put(label, ResourceLabelingAction.DELETE);
      } else {
        // if the existing label doesn't exist in the new labels (but not matching the removal
        // regex), then keep it
        if (!newLabels.containsKey(label.getKey())) {
          finalLabelsWithAction.put(label, ResourceLabelingAction.NO_CHANGE);
        }
      }
    }

    return finalLabelsWithAction;
  }

  /**
   * Remove labels that are to be deleted from the final list of labels.
   *
   * @param labelsWithAction map of labels with the action to be performed.
   * @return a map of labels with the final values to be applied.
   */
  public static Map<String, String> removeToBeDeletedLabels(
      Map<Map.Entry<String, String>, ResourceLabelingAction> labelsWithAction) {

    Map<String, String> finalLabels = new HashMap<>();

    if (labelsWithAction == null) {
      return finalLabels;
    }

    for (Map.Entry<Map.Entry<String, String>, ResourceLabelingAction> labelWithAction :
        labelsWithAction.entrySet()) {

      if (labelWithAction.getValue().equals(ResourceLabelingAction.DELETE)) {
        // when a label value is set to null it will be deleted from the resource
        finalLabels.put(labelWithAction.getKey().getKey(), null);
      } else {
        finalLabels.put(labelWithAction.getKey().getKey(), labelWithAction.getKey().getValue());
      }
    }
    return finalLabels;
  }
}
