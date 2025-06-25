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

package com.google.cloud.oss.solutions.annotations.functions.cleaner;

import com.google.cloud.oss.solutions.annotations.helpers.LoggingHelper;
import com.google.cloud.oss.solutions.annotations.helpers.Utils;
import com.google.cloud.oss.solutions.annotations.services.tags.TagsService;

import java.io.IOException;

/**
 * Main class for the GCS Annotations Cleaner function.
 *
 * <p>This class is responsible for deleting DLP-derived annotations on GCS buckets.
 */
public class GcsAnnotationsCleaner {

    private static final Integer functionNumber = 3;
    private final LoggingHelper logger;
    private final TagsService tagsService;

    public GcsAnnotationsCleaner(String hostProjectId, TagsService tagsService) {

        logger = new LoggingHelper(GcsAnnotationsCleaner.class.getSimpleName(), functionNumber, hostProjectId);
        this.tagsService = tagsService;
    }

    /**
     * @param request The request object for the cleaning operation.
     */
    public void execute(GcsBucketAnnotationsCleanerRequest request) throws IOException {

        logger.logFunctionStart(request.getTrackingId(), null);

        logger.logInfoWithTracker(
                request.getTrackingId(), null, String.format("Request : %s", request));

        // overwrite the bucket resource name after fetching the full profile
        String bucketResourceName =
                Utils.generateBucketEntityId(request.getProjectId(), request.getBucketName());

        try {

          tagsService.deleteTagBinding(request.getBucketName(), request.getTagValue());

        } catch (TagsService.ParentNotFoundException | TagsService.TagBindingNotFoundException e) {

          // log warning and continue if the target bucket or the tag binding are not there anymore
          logger.logWarnWithTracker(request.getTrackingId(), bucketResourceName, e.getMessage());
        }

        logger.logInfoWithTracker(
                request.getTrackingId(),
                bucketResourceName,
                String.format("Clean up operation of tag value '%s' on bucket '%s' completed successfully.", request.getTagValue(), bucketResourceName));

        logger.logFunctionEnd(request.getTrackingId(), bucketResourceName);
    }
}
