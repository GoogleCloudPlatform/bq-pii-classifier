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

package com.google.cloud.oss.solutions.annotations.services.findings;

import com.google.cloud.oss.solutions.annotations.entities.DlpFieldFindings;
import com.google.cloud.oss.solutions.annotations.entities.GcsDlpProfileSummary;
import com.google.cloud.oss.solutions.annotations.entities.NonRetryableApplicationException;
import java.io.IOException;
import java.util.Map;

/** Interface for reading DLP findings. */
public interface DlpFindingsReader {

  /**
   * Get the GCS DLP profile summary.
   *
   * @param fileStoreDataProfileName The name of the GCS data profile.
   * @return The GCS DLP profile summary.
   * @throws IOException If an I/O error occurs.
   * @throws NonRetryableApplicationException If a non-retryable error occurs.
   */
  GcsDlpProfileSummary getGcsDlpProfileSummary(String fileStoreDataProfileName)
      throws IOException, NonRetryableApplicationException;

  /**
   * Get the BigQuery DLP profile summary.
   *
   * @param tableProfileName The name of the BigQuery table profile.
   * @return The BigQuery DLP profile summary.
   * @throws IOException If an I/O error occurs.
   */
  Map<String, DlpFieldFindings> getBigQueryDlpProfileSummary(String tableProfileName)
      throws IOException;
}
