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

import com.google.api.services.bigquery.model.TableFieldSchema;
import com.google.cloud.bigquery.Job;
import com.google.cloud.bigquery.TableResult;
import com.google.cloud.pso.bq_pii_classifier.entities.TableSpec;

import java.io.IOException;
import java.math.BigInteger;
import java.util.List;

public interface BigQueryService {
    String getDatasetLocation(String projectId, String datasetId) throws IOException;

    Job submitJob(String query);

    TableResult waitAndGetJobResults(Job queryJob) throws InterruptedException, RuntimeException;

    List<TableFieldSchema> getTableSchemaFields(TableSpec tableSpec) throws IOException;

    void patchTable(TableSpec tableSpec, List<TableFieldSchema> updatedFields) throws IOException;

    BigInteger getTableNumRows(TableSpec tableSpec) throws IOException;
}
