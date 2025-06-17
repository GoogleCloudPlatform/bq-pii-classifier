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

import com.google.common.base.Objects;
import com.google.cloud.oss.solutions.annotations.entities.GcsDlpProfileSummary;
import com.google.cloud.oss.solutions.annotations.entities.Operation;

/** Represents a request to tag a GCS bucket based on a DLP profile summary. */
public class GcsTaggerRequest extends Operation {

  private final GcsDlpProfileSummary gcsDlpProfileSummary;

  public GcsTaggerRequest(
      String runId, String trackingId, GcsDlpProfileSummary gcsDlpProfileSummary) {
    super(runId, trackingId);
    this.gcsDlpProfileSummary = gcsDlpProfileSummary;
  }

  public GcsDlpProfileSummary getGcsDlpProfileSummary() {
    return gcsDlpProfileSummary;
  }

  @Override
  public boolean equals(Object o) {
    if (this == o) {
      return true;
    }
    if (o == null || getClass() != o.getClass()) {
      return false;
    }
    GcsTaggerRequest that = (GcsTaggerRequest) o;
    return Objects.equal(gcsDlpProfileSummary, that.gcsDlpProfileSummary);
  }

  @Override
  public int hashCode() {
    return Objects.hashCode(gcsDlpProfileSummary);
  }

  @Override
  public String toString() {
    return "GcsTaggerRequest{"
        + "gcsDlpProfileSummary="
        + gcsDlpProfileSummary
        + "} "
        + super.toString();
  }
}
