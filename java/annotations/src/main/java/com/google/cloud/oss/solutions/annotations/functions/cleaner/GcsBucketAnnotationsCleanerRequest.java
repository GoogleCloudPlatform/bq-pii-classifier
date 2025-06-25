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

import com.google.cloud.oss.solutions.annotations.entities.Operation;

public class GcsBucketAnnotationsCleanerRequest extends Operation {

    private final String projectId;
    private final String bucketName;
    private final String bucketLocation;
    private final String tagValue;

    public GcsBucketAnnotationsCleanerRequest(String runId, String trackingId,String projectId, String bucketName, String bucketLocation, String tagValue) {
        super(runId, trackingId);
        this.projectId = projectId;
        this.bucketName = bucketName;
        this.bucketLocation = bucketLocation;
        this.tagValue = tagValue;
    }

    public String getProjectId() {
        return projectId;
    }

    public String getBucketName() {
        return bucketName;
    }

    public String getBucketLocation() {
        return bucketLocation;
    }

    public String getTagValue() {
        return tagValue;
    }

    @Override
    public String toString() {
        return "GcsBucketAnnotationsCleanerRequest{" +
                "projectId='" + projectId + '\'' +
                ", bucketName='" + bucketName + '\'' +
                ", bucketLocation='" + bucketLocation + '\'' +
                ", tagValue='" + tagValue + '\'' +
                "} " + super.toString();
    }
}
