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

package com.google.cloud.oss.solutions.annotations.services.scan;

import com.google.cloud.bigquery.Job;
import com.google.cloud.bigquery.TableResult;
import com.google.common.io.Resources;
import com.google.cloud.oss.solutions.annotations.services.bq.BigQueryService;
import java.io.IOException;
import java.nio.charset.StandardCharsets;
import java.util.Map;

/**
 * Implementation of {@link DlpFindingsScanner} that uses a BigQuery query file and parameters to
 * retrieve DLP findings.
 */
public class UniversalDlpFindingsScannerImpl implements DlpFindingsScanner {
  public final BigQueryService bqService;
  private final String finalQuery;

  /**
   * Constructs a UniversalDlpFindingsScannerImpl.
   *
   * @param bqQueryFile The path to the BigQuery query file.
   * @param queryParameters A map of parameters to replace in the query file.
   * @param bqService The BigQuery service to use.
   * @throws IOException If the query file cannot be read.
   */
  public UniversalDlpFindingsScannerImpl(
      String bqQueryFile, Map<String, String> queryParameters, BigQueryService bqService)
      throws IOException {
    this.bqService = bqService;

    String query = Resources.toString(Resources.getResource(bqQueryFile), StandardCharsets.UTF_8);
    for (String param : queryParameters.keySet()) {
      query = query.replace(param, queryParameters.get(param));
    }
    finalQuery = query;
  }

  /**
   * Retrieves DLP profiles from BigQuery.
   *
   * @param runId The run ID to use in the query.
   * @return The table result from the BigQuery job.
   * @throws InterruptedException If the thread is interrupted while waiting for the job to
   *     complete.
   */
  @Override
  public TableResult getDlpProfilesFromBigQuery(String runId) throws InterruptedException {
    Job dlpFindingsJob = bqService.submitJob(finalQuery);
    return bqService.waitAndGetJobResults(dlpFindingsJob);
  }

  /**
   * Gets the final query string after all parameters have been replaced.
   *
   * @return The final query string.
   */
  public String getFinalQuery() {
    return finalQuery;
  }
}
