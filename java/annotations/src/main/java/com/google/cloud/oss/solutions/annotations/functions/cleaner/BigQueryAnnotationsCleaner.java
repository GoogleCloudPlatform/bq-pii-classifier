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

import com.google.cloud.oss.solutions.annotations.entities.NonRetryableApplicationException;
import com.google.cloud.oss.solutions.annotations.helpers.LoggingHelper;
import com.google.cloud.oss.solutions.annotations.services.tags.TagsService;

import java.io.IOException;

/**
 * Main class for the BigQuery Annotations Cleaner function.
 *
 * <p>This class is responsible for deleting DLP-derived annotations on BigQuery tables.
 */
public class BigQueryAnnotationsCleaner {

    private static final Integer functionNumber = 3;
    private final LoggingHelper logger;
    private final TagsService tagsService;
    private final String hostProjectId;

    public BigQueryAnnotationsCleaner(String hostProjectId, TagsService tagsService) {

        this.hostProjectId = hostProjectId;
        this.tagsService = tagsService;
        logger = new LoggingHelper(BigQueryAnnotationsCleaner.class.getSimpleName(),
                functionNumber, this.hostProjectId);
    }

    /**
     * @param request The request object for the cleaning operation.
     */
    public void execute(BigQueryTableAnnotationsCleanerRequest request) throws IOException,
            NonRetryableApplicationException {

        logger.logFunctionStart(request.getTrackingId(), null);

        logger.logInfoWithTracker(
                request.getTrackingId(), null, String.format("Request : %s", request));

        // overwrite the bucket resource name after fetching the full profile
        try {

          tagsService.deleteTagBindingFromTable(hostProjectId,
                  request.getTableSpec(), request.getTableLocation(), request.getTagValue());

        } catch (TagsService.ParentNotFoundException | TagsService.TagBindingNotFoundException e) {

          // log warning and continue if the target bucket or the tag binding are not there anymore
          logger.logWarnWithTracker(request.getTrackingId(), request.getTableSpec().toSqlString(), e.getMessage());
        }

        logger.logInfoWithTracker(
                request.getTrackingId(),
                request.getTableSpec().toSqlString(),
                String.format("Clean up operation of tag value '%s' on table '%s' completed successfully.",
                        request.getTagValue(), request.getTableSpec().toSqlString()));

        logger.logFunctionEnd(request.getTrackingId(), request.getTableSpec().toSqlString());
    }
}
