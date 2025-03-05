/*
 * Copyright 2022 Google LLC
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

package com.google.cloud.pso.bq_pii_classifier.services.scan;

import com.google.cloud.bigquery.Job;
import com.google.cloud.bigquery.TableResult;
import com.google.cloud.pso.bq_pii_classifier.services.bq.BigQueryService;
import com.google.common.io.Resources;

import java.io.IOException;
import java.nio.charset.StandardCharsets;
import java.util.Map;

public class UniversalDlpFindingsScannerImpl implements DlpFindingsScanner {
    private final String bqQueryFile;
    private final Map<String, String> queryParameters;
    public final BigQueryService bqService;

    public UniversalDlpFindingsScannerImpl(String bqQueryFile,
                                           Map<String, String> queryParameters,
                                           BigQueryService bqService) {
        this.bqQueryFile = bqQueryFile;
        this.queryParameters = queryParameters;
        this.bqService = bqService;
    }

    @Override
    public TableResult getDlpProfilesFromBigQuery(String runId)
            throws IOException, InterruptedException {

        String query = Resources.toString(Resources.getResource(bqQueryFile),
                        StandardCharsets.UTF_8);

        for(String param: queryParameters.keySet()){
            query = query.replace(param, queryParameters.get(param));
        }

        Job dlpFindingsJob = bqService.submitJob(query);
        return bqService.waitAndGetJobResults(dlpFindingsJob);
    }
}
