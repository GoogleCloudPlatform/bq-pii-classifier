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

package com.google.cloud.oss.solutions.annotations.services.gcs;

import com.google.cloud.storage.Bucket;
import com.google.cloud.storage.Storage;
import com.google.cloud.storage.StorageOptions;
import com.google.cloud.oss.solutions.annotations.entities.NonRetryableApplicationException;
import com.google.cloud.oss.solutions.annotations.entities.ResourceLabelingAction;
import com.google.cloud.oss.solutions.annotations.helpers.LabelsHelper;
import java.util.HashMap;
import java.util.Map;

/** Implementation of the GcsService interface. */
public class GcsServiceImpl implements GcsService {

  private final Storage storage;

  public GcsServiceImpl() {
    this.storage = StorageOptions.newBuilder().build().getService();
  }

  /**
   * Merges new labels to an existing bucket, it validates the existing labels with a regex.
   *
   * @param bucketName The name of the bucket to update.
   * @param newLabels A map of new labels to add.
   * @param existingLabelsRegex A regex to validate the existing labels.
   * @param isDryRun If true, the bucket will not be updated.
   * @return A map of the final labels with the action that was performed.
   * @throws NonRetryableApplicationException If the bucket is not found or if the labels are not
   *     valid.
   */
  public Map<Map.Entry<String, String>, ResourceLabelingAction> mergeLabelsToBucket(
      String bucketName,
      Map<String, String> newLabels,
      String existingLabelsRegex,
      boolean isDryRun)
      throws NonRetryableApplicationException {

    if (newLabels == null || newLabels.isEmpty()) {
      return new HashMap<>();
    }

    Bucket bucket = storage.get(bucketName);

    if (bucket == null) {
      throw new NonRetryableApplicationException(String.format("Bucket %s not found.", bucketName));
    }

    // create a mutable map for existing bucket labels
    Map<String, String> bucketLabels;
    if (bucket.getLabels() == null) {
      bucketLabels = new HashMap<>();
    } else {
      bucketLabels = new HashMap<>(bucket.getLabels());
    }

    Map<Map.Entry<String, String>, ResourceLabelingAction> finalLabelsWithActions =
        LabelsHelper.computeLabelsActions(bucketLabels, newLabels, existingLabelsRegex);

    Map<String, String> labelsToAttach =
        LabelsHelper.removeToBeDeletedLabels(finalLabelsWithActions);

    if (!isDryRun) {
      Bucket updatedBucket = bucket.toBuilder().setLabels(labelsToAttach).build();
      storage.update(updatedBucket);
    }

    return finalLabelsWithActions;
  }

  /**
   * Get the content of a file from GCS.
   *
   * @param gcsFilePath The path of the file to get.
   * @return The content of the file.
   * @throws NonRetryableApplicationException If the file path is invalid or if the file is not
   *     found.
   */
  @Override
  public String getFileContent(String gcsFilePath) throws NonRetryableApplicationException {

    if (gcsFilePath == null || gcsFilePath.isEmpty()) {
      throw new NonRetryableApplicationException("GCS File Path cannot be null or empty.");
    }

    if (!gcsFilePath.startsWith("gs://")) {
      throw new NonRetryableApplicationException(
          String.format("Invalid GCS File Path: %s. It should start with gs://", gcsFilePath));
    }

    String[] parts = gcsFilePath.substring(5).split("/", 2);

    if (parts.length != 2) {
      throw new NonRetryableApplicationException(
          String.format(
              "Invalid GCS File Path: %s. It should be in the format gs://<bucket>/<path>",
              gcsFilePath));
    }

    String bucketName = parts[0];
    String objectName = parts[1];

    return new String(storage.readAllBytes(bucketName, objectName));
  }
}
