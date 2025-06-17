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

import com.google.cloud.oss.solutions.annotations.entities.NonRetryableApplicationException;
import com.google.cloud.oss.solutions.annotations.entities.ResourceLabelingAction;
import java.util.Map;

/** Interface for interacting with Google Cloud Storage. */
public interface GcsService {

  /**
   * @param bucketName the bucket to be updated
   * @param newLabels the map of labels to be attached to the bucket
   * @param existingLabelsRegex a regex to match existing bucket labels to be deleted before adding
   *     the new labels.
   * @param isDryRun if true, the bucket will not be updated.
   * @return the final map of labels that is attached to the bucket
   * @throws NonRetryableApplicationException if there is an error updating the bucket.
   */
  Map<Map.Entry<String, String>, ResourceLabelingAction> mergeLabelsToBucket(
      String bucketName,
      Map<String, String> newLabels,
      String existingLabelsRegex,
      boolean isDryRun)
      throws NonRetryableApplicationException;

  /**
   * Retrieves the content of a file stored in Google Cloud Storage.
   *
   * @param gcsFilePath The GCS path of the file to read, in the format gs://bucket-name/file-path.
   * @return The content of the file as a String.
   * @throws NonRetryableApplicationException If there is an error reading the file.
   */
  String getFileContent(String gcsFilePath) throws NonRetryableApplicationException;
}
