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

package com.google.cloud.oss.solutions.annotations.entities;

import com.google.common.base.Objects;
import com.google.privacy.dlp.v2.FileStoreDataProfile;
import java.util.Collections;
import java.util.Set;
import java.util.stream.Collectors;

/**
 * Represents a summary of a GCS DLP profile, including relevant details such as bucket path,
 * project ID, folder ID, and detected info types.
 */
public class GcsDlpProfileSummary {

  private final String fileStoreProfileName;
  private final String bucketPath;
  private final String bucketName;
  private final String projectId;
  private final String folderId;
  private final Set<String> infoTypes; // New field, optional

  public GcsDlpProfileSummary(
      String fileStoreProfileName,
      String bucketPath,
      String projectId,
      String folderId,
      Set<String> infoTypes) {
    this.fileStoreProfileName = fileStoreProfileName;

    if (!bucketPath.startsWith("gs://")) {
      throw new IllegalArgumentException(
          String.format(
              "bucketPath must start with gs://. Provided bucketPath is '%s'", bucketPath));
    }
    this.bucketPath = bucketPath;
    this.bucketName = bucketPath.substring(5);
    this.projectId = projectId == null ? "" : projectId;
    this.folderId = folderId == null ? "" : folderId;
    this.infoTypes =
        infoTypes == null
            ? Collections.emptySet()
            : Set.copyOf(infoTypes); // Handle null, make immutable
  }

  // used by the dispatcher app when called by the DLP pubsub notification
  public GcsDlpProfileSummary(String fileStoreProfileName, String bucketPath) {
    this(fileStoreProfileName, bucketPath, null, null, null); // Constructor without infoTypes
  }

  public static GcsDlpProfileSummary fromDlpFileStoreDataProfile(FileStoreDataProfile profile) {
    return new GcsDlpProfileSummary(
        profile.getName(),
        profile.getFileStorePath(),
        profile.getProjectId(),
        String.valueOf(
            profile
                .getConfigSnapshot()
                .getDiscoveryConfig()
                .getOrgConfig()
                .getLocation()
                .getFolderId()),
        profile.getFileStoreInfoTypeSummariesList().stream()
            .map(x -> x.getInfoType().getName())
            .collect(Collectors.toSet()));
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
    return !infoTypes.isEmpty(); // Check if infoTypes is not empty
  }

  public String getFolderId() {
    return folderId;
  }

  @Override
  public String toString() {
    return "GcsDlpProfileSummary{"
        + "fileStoreProfileName='"
        + fileStoreProfileName
        + '\''
        + ", bucketPath='"
        + bucketPath
        + '\''
        + ", bucketName='"
        + bucketName
        + '\''
        + ", projectId='"
        + projectId
        + '\''
        + ", folderId='"
        + folderId
        + '\''
        + ", infoTypes="
        + infoTypes
        + '}';
  }

  @Override
  public boolean equals(Object o) {
    if (this == o) {
      return true;
    }
    if (o == null || getClass() != o.getClass()) {
      return false;
    }
    GcsDlpProfileSummary that = (GcsDlpProfileSummary) o;
    return Objects.equal(fileStoreProfileName, that.fileStoreProfileName)
        && Objects.equal(bucketPath, that.bucketPath)
        && Objects.equal(infoTypes, that.infoTypes);
  }

  @Override
  public int hashCode() {
    return Objects.hashCode(fileStoreProfileName, bucketPath, infoTypes);
  }
}
