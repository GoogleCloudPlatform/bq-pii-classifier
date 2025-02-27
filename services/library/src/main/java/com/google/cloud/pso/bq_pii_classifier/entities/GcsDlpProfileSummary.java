/*
 * Copyright 2025 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     https://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

package com.google.cloud.pso.bq_pii_classifier.entities;

import com.google.common.base.Objects;
import com.google.privacy.dlp.v2.FileStoreDataProfile;

import java.util.Collections;
import java.util.Set;
import java.util.stream.Collectors;

public class GcsDlpProfileSummary{

    private final String fileStoreProfileName;
    private final String bucketPath;
    private final String bucketName;
    private final String projectId;
    private final Set<String> infoTypes; // New field, optional

    public GcsDlpProfileSummary(String bucketName, String projectId, Set<String> infoTypes){


        if (bucketName.startsWith("gs://")) {
            throw new IllegalArgumentException(String.format(
                    "bucketName should not start with gs://. Provided bucketName is '%s'",
                    bucketName));
        }

        this.bucketName = bucketName;
        this.bucketPath = String.format("gs://%s", bucketName);
        this.projectId = projectId;
        this.infoTypes = infoTypes;
        this.fileStoreProfileName = null;
    }

    public GcsDlpProfileSummary(String fileStoreProfileName, String bucketPath, String projectId, Set<String> infoTypes) {
        this.fileStoreProfileName = fileStoreProfileName;

        if (!bucketPath.startsWith("gs://")) {
            throw new IllegalArgumentException(String.format(
                    "bucketPath must start with gs://. Provided bucketPath is '%s'",
                    bucketPath));
        }
        this.bucketPath = bucketPath;
        this.bucketName = bucketPath.substring(5);
        this.projectId = projectId == null? "": projectId;
        this.infoTypes = infoTypes == null? Collections.emptySet(): Set.copyOf(infoTypes); // Handle null, make immutable
    }


    public GcsDlpProfileSummary(String fileStoreProfileName, String bucketPath) {
        this(fileStoreProfileName, bucketPath, null, null); // Constructor without infoTypes
    }

    public String getProjectId() {
        return projectId;
    }

    public String getFileStoreProfileName() {
        return fileStoreProfileName;
    }

    public String getBucketPath() {
        return bucketPath;
    }

    public String getBucketName() {
        return bucketName;
    }

    public Set<String> getInfoTypes() {
        return infoTypes;
    }

    public boolean hasInfoTypes() {
        return!infoTypes.isEmpty(); // Check if infoTypes is not empty
    }

    @Override
    public String toString() {
        return "GcsTaggerRequest{" +
                "fileStoreProfileName='" + fileStoreProfileName + '\'' +
                ", bucketPath='" + bucketPath + '\'' +
                ", bucketName='" + bucketName + '\'' +
                ", infoTypes='" + infoTypes + '\'' +
                "} ";
    }

    @Override
    public boolean equals(Object o) {
        if (this == o) return true;
        if (o == null || getClass()!= o.getClass()) return false;
        GcsDlpProfileSummary that = (GcsDlpProfileSummary) o;
        return Objects.equal(fileStoreProfileName, that.fileStoreProfileName) && Objects.equal(bucketPath, that.bucketPath) && Objects.equal(infoTypes, that.infoTypes);
    }

    @Override
    public int hashCode() {
        return Objects.hashCode(fileStoreProfileName, bucketPath, infoTypes);
    }

    public static GcsDlpProfileSummary fromDlpFileStoreDataProfile(FileStoreDataProfile profile) {
        return new GcsDlpProfileSummary(
                profile.getName(),
                profile.getFileStorePath(),
                profile.getProjectId(),
                profile.getFileStoreInfoTypeSummariesList().stream().map(x->x.getInfoType().getName()).collect(Collectors.toSet())
        );
    }
}