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

package com.google.cloud.pso.bq_pii_classifier.functions.tagger.gcs;

import com.google.cloud.pso.bq_pii_classifier.entities.Operation;
import com.google.common.base.Objects;

public class GcsTaggerRequest extends Operation {
    
    private final String fileStoreProfileName;
    private final String bucketPath;
    private final String bucketName;

    public GcsTaggerRequest(String runId, String trackingId, String fileStoreProfileName, String bucketPath) {
        super(runId, trackingId);
        this.fileStoreProfileName = fileStoreProfileName;

        if(!bucketPath.startsWith("gs://")){
            throw new IllegalArgumentException(String.format(
                    "bucketPath must start with gs://. Provided bucketPath is '%s'",
                    bucketPath)

            );
        }
        this.bucketPath = bucketPath;
        this.bucketName = bucketPath.substring(5);
    }

    public String getFileStoreProfileName() {
        return fileStoreProfileName;
    }

    public String getBucketPath(){return bucketPath;}

    public String getBucketName(){return bucketName;}

    @Override
    public String toString() {
        return "GcsTaggerRequest{" +
                "fileStoreProfileName='" + fileStoreProfileName + '\'' +
                "bucketPath='" + bucketPath + '\'' +
                "bucketName='" + bucketName + '\'' +
                "} " + super.toString();
    }

    @Override
    public boolean equals(Object o) {
        if (this == o) return true;
        if (o == null || getClass() != o.getClass()) return false;
        GcsTaggerRequest that = (GcsTaggerRequest) o;
        return Objects.equal(fileStoreProfileName, that.fileStoreProfileName) && Objects.equal(bucketPath, that.bucketPath);
    }

    @Override
    public int hashCode() {
        return Objects.hashCode(fileStoreProfileName, bucketPath);
    }
}
