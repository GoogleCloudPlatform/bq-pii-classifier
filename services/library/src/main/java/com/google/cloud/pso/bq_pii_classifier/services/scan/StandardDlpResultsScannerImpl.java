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

public class StandardDlpResultsScannerImpl implements Scanner {

    private String hostProject;
    private String hostDataset;
    private String dlpFindingsTable;
    private String dlpLoggingTable;
    public BigQueryService bqService;

    public StandardDlpResultsScannerImpl(String hostProject, String hostDataset, String dlpFindingsTable, String dlpLoggingTable, BigQueryService bqService) {
        this.hostProject = hostProject;
        this.hostDataset = hostDataset;
        this.dlpFindingsTable = dlpFindingsTable;
        this.dlpLoggingTable = dlpLoggingTable;
        this.bqService = bqService;
    }

    public String getDlpFindingsTable() {
        return dlpFindingsTable;
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
    // List all datasets under this project that have DLP results
    // return: List("project.dataset")
    public List<String> listParents(String project) throws NonRetryableApplicationException, InterruptedException {

        String queryTemplate =
                "SELECT \n" +
                "DISTINCT \n" +
                "CONCAT(l.record_location.record_key.big_query_key.table_reference.project_id, '.', l.record_location.record_key.big_query_key.table_reference.dataset_id) AS dataset \n" +
                "FROM `%s.%s.%s` , UNNEST(location.content_locations) l\n" +
                "WHERE l.record_location.record_key.big_query_key.table_reference.project_id = '%s'\n";

        String formattedQuery = String.format(queryTemplate,
                hostProject,
                hostDataset,
                dlpFindingsTable,
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
    // List the last dlp job IDs for each table included under a project/dataset
    // We return the jobName and not the table spec because this column is clustered and the Tagger can utilize that for lookups
    public List<String> listChildren(String project, String dataset) throws InterruptedException, NonRetryableApplicationException {

        // dlp job names start with unix timestamp. Max() will get us the latest job
        String queryTemplate =
        "SELECT DISTINCT\n" +
                "l.record_location.record_key.big_query_key.table_reference.table_id,\n" +
                "MAX(job_name) AS latest_job_name\n" +
                "FROM \n" +
                "`%s.%s.%s`, UNNEST(location.content_locations) l\n" +
                "WHERE l.record_location.record_key.big_query_key.table_reference.project_id = '%s'\n" +
                "AND l.record_location.record_key.big_query_key.table_reference.dataset_id  = '%s'\n" +
                "GROUP BY 1\n" +
                "ORDER BY 1,2 DESC\n";

        String formattedQuery = String.format(queryTemplate,
                hostProject,
                hostDataset,
                dlpFindingsTable,
                project,
                dataset
        );

        // Create a job ID so that we can safely retry.
        Job queryJob = bqService.submitJob(formattedQuery);

        TableResult result = bqService.waitAndGetJobResults(queryJob);

        // Construct a mapping between field names and DLP infotypes
        List<String> datasetTablesDlpJobs = new ArrayList<>();
        for (FieldValueList row : result.iterateAll()) {

            if (row.get("latest_job_name").isNull()) {
                throw new NonRetryableApplicationException("processDatasets query returned rows with null 'latest_job_name' field.");
            }
            String jobName = row.get("latest_job_name").getStringValue();
            datasetTablesDlpJobs.add(jobName);
        }

        return datasetTablesDlpJobs;
    }
}
