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

package com.google.cloud.pso.bq_pii_classifier.services.bq;

import com.google.api.client.http.javanet.NetHttpTransport;
import com.google.api.client.json.jackson2.JacksonFactory;
import com.google.api.services.bigquery.BigqueryScopes;
import com.google.api.services.bigquery.model.TableFieldSchema;
import com.google.api.services.bigquery.model.TableSchema;
import com.google.auth.http.HttpCredentialsAdapter;
import com.google.auth.oauth2.GoogleCredentials;
import com.google.cloud.bigquery.*;
import com.google.cloud.pso.bq_pii_classifier.entities.TableSpec;
import com.google.api.services.bigquery.model.Table;

import java.io.IOException;
import java.math.BigInteger;
import java.util.List;
import java.util.Map;
import java.util.UUID;

public class BigQueryServiceImpl implements BigQueryService {

    private com.google.api.services.bigquery.Bigquery bqAPI;
    private BigQuery bqAPIWrapper;

    public BigQueryServiceImpl() throws IOException {
        bqAPIWrapper = BigQueryOptions.getDefaultInstance().getService();

        // direct API calls are needed for some operations
        // TODO: follow up on the missing/faulty wrapper calls and stop using direct API calls
        bqAPI = new com.google.api.services.bigquery.Bigquery.Builder(
                new NetHttpTransport(),
                new JacksonFactory(),
                new HttpCredentialsAdapter(GoogleCredentials
                        .getApplicationDefault()
                        .createScoped(BigqueryScopes.all())))
                .setApplicationName("bq-security-classifier")
                .build();
    }

    @Override
    public String getDatasetLocation(String projectId, String datasetId) throws IOException {
        // calling dataset.getLocation always returns null --> seems like a bug in the SDK
        // instead, use the underlying API call to get dataset info
        return bqAPI.datasets()
                .get(projectId, datasetId)
                .execute()
                .getLocation();
    }

    @Override
    public Job submitJob(String query) {

        QueryJobConfiguration queryConfig =
                QueryJobConfiguration.newBuilder(query)
                        .setUseLegacySql(false)
                        // Use Interactive priority to avoid waiting idle and timing out the cloud run request
                        // Interactive queries have a limit of 100 concurrent ones. This is handled by
                        // Cloud run number of parallel requests and PubSub retries
                        .setPriority(QueryJobConfiguration.Priority.INTERACTIVE)
                        .build();

        JobId jobId = JobId.of(UUID.randomUUID().toString());
        return bqAPIWrapper.create(JobInfo.newBuilder(queryConfig).setJobId(jobId).build());
    }

    @Override
    public TableResult waitAndGetJobResults(Job queryJob) throws InterruptedException, RuntimeException {

        // Wait for the query to complete.

        queryJob = queryJob.waitFor();

        // Check for errors
        if (queryJob == null) {
            throw new RuntimeException("Job no longer exists");
        } else // You can also look at queryJob.getStatus().getExecutionErrors() for all
            // errors, not just the latest one.
            if (queryJob.getStatus().getError() != null) {
                throw new RuntimeException(queryJob.getStatus().getError().toString());
            }

        return queryJob.getQueryResults();
    }

    @Override
    public List<TableFieldSchema> getTableSchemaFields(TableSpec tableSpec) throws IOException {

        return bqAPI.tables()
                .get(tableSpec.getProject(), tableSpec.getDataset(), tableSpec.getTable())
                .execute()
                .getSchema()
                .getFields();
    }

    @Override
    public void patchTable(TableSpec tableSpec,
                           List<TableFieldSchema> updatedFields,
                           Map<String, String> tableLabels) throws IOException {
        patchTable(tableSpec,
                new Table()
                        .setSchema(new TableSchema().setFields(updatedFields))
                        .setLabels(tableLabels));
    }

    @Override
    public void patchTableSchema(TableSpec tableSpec, List<TableFieldSchema> updatedFields) throws IOException {
        patchTable(tableSpec,
                new Table()
                        .setSchema(new TableSchema().setFields(updatedFields)));
    }


    @Override
    public void patchTableLabels(TableSpec tableSpec, Map<String, String> tableLabels) throws IOException {
        patchTable(tableSpec,
                new Table()
                        .setLabels(tableLabels));
    }

    private void patchTable(TableSpec tableSpec, Table newTableModel) throws IOException {

        bqAPI.tables()
                .patch(tableSpec.getProject(),
                        tableSpec.getDataset(),
                        tableSpec.getTable(),
                        newTableModel)
                .execute();
    }

    @Override
    public BigInteger getTableNumRows(TableSpec tableSpec) throws IOException {
        return bqAPI.tables()
                .get(tableSpec.getProject(), tableSpec.getDataset(), tableSpec.getTable())
                .execute()
                .getNumRows();
    }

    @Override
    public boolean tableExists(TableSpec tableSpec) {
        return bqAPIWrapper.getTable(tableSpec.toTableId()) != null;
    }
}
