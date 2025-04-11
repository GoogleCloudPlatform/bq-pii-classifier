package com.google.cloud.pso.bq_pii_classifier.services.gcs;

import com.google.cloud.pso.bq_pii_classifier.entities.NonRetryableApplicationException;
import com.google.cloud.pso.bq_pii_classifier.entities.ResourceLabelingAction;
import java.util.Map;

public interface GcsService {

  /**
   * @param bucketName the bucket to be updated
   * @param newLabels the map of labels to be attached to the bucket
   * @param existingLabelsRegex a regex to match existing bucket labels to be deleted before adding
   *     the new labels
   * @throws NonRetryableApplicationException
   * @return the final map of labels that is attached to the bucket
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
