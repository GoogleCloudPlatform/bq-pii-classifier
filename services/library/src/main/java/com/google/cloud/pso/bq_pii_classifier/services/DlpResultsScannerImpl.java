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

package com.google.cloud.pso.bq_pii_classifier.services;

import com.google.cloud.bigquery.FieldValueList;
import com.google.cloud.bigquery.Job;
import com.google.cloud.bigquery.TableResult;
import com.google.cloud.pso.bq_pii_classifier.entities.NonRetryableApplicationException;

import java.util.ArrayList;
import java.util.List;

public class DlpResultsScannerImpl implements Scanner {

    private String dlpFindingsView;
    public BigQueryService bqService;

    public DlpResultsScannerImpl(BigQueryService bqService, String dlpFindingsView){
        this.bqService = bqService;
        this.dlpFindingsView = dlpFindingsView;
    }

    public String getDlpFindingsView() {
        return dlpFindingsView;
    }

    public BigQueryService getBqService(){
        return bqService;
    }

    @Override
    // List all datasets in a project that have tables containing DLP findings
    // return: List("project.dataset")
    public List<String> listDatasets(String project) throws NonRetryableApplicationException, InterruptedException {
        // Get all tables under this dataset that was scanned by DLP
        String formattedQuery = String.format(
                "SELECT DISTINCT CONCAT(project_id, '.', dataset_id) AS dataset FROM `%s` WHERE project_id = '%s'",
                dlpFindingsView,
                project
        );

        // Create a job ID so that we can safely retry.
        Job queryJob = bqService.submitJob(formattedQuery);

        TableResult result = bqService.waitAndGetJobResults(queryJob);

        List<String> projectDatasets = new ArrayList<>();
        // Construct a mapping between field names and DLP infotypes
        for (FieldValueList row : result.iterateAll()) {

            if (row.get("dataset").isNull()) {
                throw new NonRetryableApplicationException("processProjects query returned rows with null 'dataset' field.");
            }
            String datasetSpec = row.get("dataset").getStringValue();
            projectDatasets.add(datasetSpec);
        }
        return projectDatasets;
    }

    @Override
    // List all tables in a dataset/project that have DLP findings
    public List<String> listTables(String project, String dataset) throws InterruptedException, NonRetryableApplicationException {
        // Get all tables under this dataset that was scanned by DLP
        String formattedQuery = String.format(
                "SELECT DISTINCT table_spec AS table FROM `%s` WHERE CONCAT(project_id, '.', dataset_id) = '%s.%s'",
                dlpFindingsView,
                project,
                dataset
        );

        // Create a job ID so that we can safely retry.
        Job queryJob = bqService.submitJob(formattedQuery);

        TableResult result = bqService.waitAndGetJobResults(queryJob);

        // Construct a mapping between field names and DLP infotypes
        List<String> datasetTables = new ArrayList<>();
        for (FieldValueList row : result.iterateAll()) {

            if (row.get("table").isNull()) {
                throw new NonRetryableApplicationException("processDatasets query returned rows with null 'table' field.");
            }
            String tableSpec = row.get("table").getStringValue();
            datasetTables.add(tableSpec);
        }

        return datasetTables;
    }
}
