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

package com.google.cloud.oss.solutions.annotations.functions.tagger.gcs;

import com.google.cloud.oss.solutions.annotations.entities.GcsDlpProfileSummary;
import com.google.cloud.oss.solutions.annotations.entities.InfoTypeInfo;
import com.google.cloud.oss.solutions.annotations.entities.NonRetryableApplicationException;
import com.google.cloud.oss.solutions.annotations.entities.ResourceLabel;
import com.google.cloud.oss.solutions.annotations.entities.ResourceLabelingAction;
import com.google.cloud.oss.solutions.annotations.helpers.LoggingHelper;
import com.google.cloud.oss.solutions.annotations.helpers.Utils;
import com.google.cloud.oss.solutions.annotations.services.findings.DlpFindingsReader;
import com.google.cloud.oss.solutions.annotations.services.gcs.GcsService;
import java.io.IOException;
import java.util.HashMap;
import java.util.Map;
import java.util.Set;
import java.util.stream.Collectors;

/**
 * Main class for the GCS tagger function.
 *
 * <p>This class is responsible for tagging GCS buckets based on the DLP findings.
 */
public class GcsTagger {

  private static final Integer functionNumber = 3;
  private final LoggingHelper logger;
  private final GcsTaggerConfig config;

  private final DlpFindingsReader findingsReader;

  private final GcsService gcsService;

  public GcsTagger(
      GcsTaggerConfig config, DlpFindingsReader findingsReader, GcsService gcsService) {

    this.config = config;
    this.findingsReader = findingsReader;
    this.gcsService = gcsService;

    logger = new LoggingHelper(GcsTagger.class.getSimpleName(), functionNumber, config.projectId());
  }

  /**
   * @param infoTypes A list of info types names
   * @param infoTypeMetadataMap A Map<info type name, info type metadata>
   * @return A subset of map infoTypeMetadataMap with only the info type entries/keys that are found
   *     in infoTypes
   */
  public static Map<String, InfoTypeInfo> filterInfoTypesMetadataMap(
      Set<String> infoTypes, Map<String, InfoTypeInfo> infoTypeMetadataMap) {

    return infoTypeMetadataMap.entrySet().stream()
        .filter(entry -> infoTypes.contains(entry.getKey()))
        .collect(Collectors.toMap(Map.Entry::getKey, Map.Entry::getValue));
  }

  /**
   * @param infoTypesFindings A list of info types names that are detected by DLP in a bucket
   * @param infoTypeMetadataMap A Map<info type name, info type metadata> used as master data for
   *     lookup
   * @return A map of label key, label value pairs that are configured for all info types in the
   *     infoTypesFindings list
   */
  public static Map<String, String> generateBucketLabelsFromDlpFindings(
      Set<String> infoTypesFindings, Map<String, InfoTypeInfo> infoTypeMetadataMap) {
    Map<String, String> bucketLabels = new HashMap<>();
    // loop on all InfoTyps found in that bucket
    for (String infoType : infoTypesFindings) {
      // lookup the labels associated with that info type based on the classification taxonomy (in
      // Terraform)
      // add each label to the map. Duplicate labels across InfoTypes will be overwritten.
      InfoTypeInfo infoTypeInfo = infoTypeMetadataMap.get(infoType);
      if (infoTypeInfo != null) {
        for (ResourceLabel infoTypeLabel : infoTypeInfo.labels()) {
          bucketLabels.put(infoTypeLabel.key().toLowerCase(), infoTypeLabel.value().toLowerCase());
        }
      }
    }
    return bucketLabels;
  }

  /**
   * @param request The request object for the tagging operation.
   * @param pubSubMessageId The pub sub message id containing the request. This is used to ensure
   *     exactly once processing
   * @return A map of detected InfoTypes names and the metadata configured for each one of them .
   */
  public Map<String, InfoTypeInfo> execute(GcsTaggerRequest request)
      throws NonRetryableApplicationException, IOException {

    logger.logFunctionStart(request.getTrackingId(), null);
    logger.logInfoWithTracker(
        request.getTrackingId(), null, String.format("Request : %s", request));

    // get the complete profile summary, either already supplied by the dispatcher or from DLP Api
    // in case an incomplete profile is sent via the auto-dlp
    GcsDlpProfileSummary profileSummary;
    if (request.getGcsDlpProfileSummary().hasInfoTypes()) {
      profileSummary = request.getGcsDlpProfileSummary();
    } else {
      profileSummary =
          findingsReader.getGcsDlpProfileSummary(
              request.getGcsDlpProfileSummary().getFileStoreProfileName());
    }

    // overwrite the bucket resource name after fetching the full profile
    String bucketResourceName =
        Utils.generateBucketEntityId(profileSummary.getProjectId(), profileSummary.getBucketName());

    logger.logInfoWithTracker(
        request.getTrackingId(),
        bucketResourceName,
        String.format("Computed profile summary: %s ", profileSummary));

    Map<String, InfoTypeInfo> detectedInfoTypesWithMetadata =
        filterInfoTypesMetadataMap(profileSummary.getInfoTypes(), config.infoTypeMap());

    logger.logInfoWithTracker(
        request.getTrackingId(),
        bucketResourceName,
        String.format(
            "detected info types with metadata: %s", detectedInfoTypesWithMetadata.size()));

    // construct a map of label key, label value based on all labels configured for all detected
    // info types
    Map<String, String> bucketLabelsFromDlpFindings =
        generateBucketLabelsFromDlpFindings(
            profileSummary.getInfoTypes(), detectedInfoTypesWithMetadata);

    // compute which labels to add, keep or remove. And execute the actions based on
    // config.isDryRunLabels()
    Map<Map.Entry<String, String>, ResourceLabelingAction> labelsWithActions =
        gcsService.mergeLabelsToBucket(
            profileSummary.getBucketName(),
            bucketLabelsFromDlpFindings,
            config.existingLabelsRegex(),
            config.isDryRunLabels());

    // log labels and actions applied on this bucket
    int deletedLabelsCount = 0;
    int newLabelsCount = 0;
    int modifiedLabelsCount = 0;
    int unchangedLabelsCount = 0;

    for (Map.Entry<Map.Entry<String, String>, ResourceLabelingAction> labelWithAction :
        labelsWithActions.entrySet()) {

      switch (labelWithAction.getValue()) {
        case DELETE -> deletedLabelsCount += 1;
        case NEW_KEY -> newLabelsCount += 1;
        case NEW_VALUE -> modifiedLabelsCount += 1;
        case NO_CHANGE -> unchangedLabelsCount += 1;
      }

      logger.logBucketLabelsHistory(
          profileSummary.getBucketName(),
          profileSummary.getProjectId(),
          labelWithAction.getKey().getKey(),
          labelWithAction.getKey().getValue(),
          config.isDryRunLabels(),
          labelWithAction.getValue(),
          request.getTrackingId());
    }

    logger.logInfoWithTracker(
        request.getTrackingId(),
        bucketResourceName,
        String.format(
            "Labels Summary: bucket = %s, is_dry_run_labels = %s, new labels = %s, changed values ="
                + " %s, no change = %s, deleted = %s .",
            profileSummary.getBucketPath(),
            config.isDryRunLabels(),
            newLabelsCount,
            modifiedLabelsCount,
            unchangedLabelsCount,
            deletedLabelsCount));

    logger.logFunctionEnd(request.getTrackingId(), bucketResourceName);

    return detectedInfoTypesWithMetadata;
  }
}
