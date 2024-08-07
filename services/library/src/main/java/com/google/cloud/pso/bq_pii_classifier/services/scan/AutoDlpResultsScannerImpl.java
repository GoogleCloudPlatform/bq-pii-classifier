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

import com.google.cloud.bigquery.FieldValueList;
import com.google.cloud.bigquery.Job;
import com.google.cloud.bigquery.TableResult;
import com.google.cloud.pso.bq_pii_classifier.entities.NonRetryableApplicationException;
import com.google.cloud.pso.bq_pii_classifier.services.bq.BigQueryService;

import java.util.ArrayList;
import java.util.List;

public class AutoDlpResultsScannerImpl implements Scanner {

    private String hostProject;
    private String hostDataset;
    private String dlpLatestFindingsView;
    public BigQueryService bqService;

    public AutoDlpResultsScannerImpl(String hostProject, String hostDataset, String dlpLatestFindingsView, BigQueryService bqService) {
        this.hostProject = hostProject;
        this.hostDataset = hostDataset;
        this.dlpLatestFindingsView = dlpLatestFindingsView;
        this.bqService = bqService;
    }

    public String getDlpLatestFindingsView() {
        return dlpLatestFindingsView;
    }

    public BigQueryService getBqService(){
        return bqService;
    }

    public String getHostProject() {
        return hostProject;
    }

    public String getHostDataset() {
        return hostDataset;
    }

    @Override
    // List all unique datasets under a given project that have DLP findings/profiles
    // Datasets that no longer exist on BQ are omitted via the join with information schema
    // return: List("project.dataset")
    public List<String> listParents(String project) throws NonRetryableApplicationException, InterruptedException {

        String queryTemplate = "SELECT DISTINCT " +
                "CONCAT(column_profile.dataset_project_id, '.', column_profile.dataset_id) AS dataset " +
                "FROM %s.%s.%s r " +
                "INNER JOIN %s.INFORMATION_SCHEMA.SCHEMATA s ON s.schema_name = r.column_profile.dataset_id " +
                "WHERE r.column_profile.dataset_project_id = '%s'";

        String formattedQuery = String.format(queryTemplate,
                hostProject,
                hostDataset,
                dlpLatestFindingsView,
                project,
                project
        );

        Job queryJob = bqService.submitJob(formattedQuery);

        TableResult result = bqService.waitAndGetJobResults(queryJob);

        List<String> projectDatasets = new ArrayList<>();
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
    // List all unique tables under a given dataset that have DLP findings/profiles
    // return: List("project.dataset.table")
    public List<String> listChildren(String project, String dataset) throws InterruptedException, NonRetryableApplicationException {

        String queryTemplate = "SELECT DISTINCT CONCAT(column_profile.dataset_project_id, '.', column_profile.dataset_id, '.', column_profile.table_id) AS table FROM %s.%s.%s WHERE column_profile.dataset_project_id = '%s' AND column_profile.dataset_id = '%s'";

        String formattedQuery = String.format(queryTemplate,
                hostProject,
                hostDataset,
                dlpLatestFindingsView,
                project,
                dataset
        );

        // Create a job ID so that we can safely retry.
        Job queryJob = bqService.submitJob(formattedQuery);

        TableResult result = bqService.waitAndGetJobResults(queryJob);

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
