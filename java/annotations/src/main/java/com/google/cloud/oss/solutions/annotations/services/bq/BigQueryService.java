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

package com.google.cloud.oss.solutions.annotations.services.bq;

import com.google.api.services.bigquery.model.TableFieldSchema;
import com.google.cloud.bigquery.Job;
import com.google.cloud.bigquery.TableResult;
import com.google.cloud.oss.solutions.annotations.entities.TableSpec;
import java.io.IOException;
import java.math.BigInteger;
import java.util.List;
import java.util.Map;

/**
 * Interface for BigQuery service.
 *
 * <p>This interface provides methods to interact with BigQuery, such as getting dataset location,
 * submitting jobs, getting table schema, patching table schema, patching table labels, getting
 * table number of rows, getting table labels, checking if a table exists and overwriting table
 * labels.
 */
public interface BigQueryService {
  /**
   * Get the location of a BigQuery dataset.
   *
   * @param projectId The ID of the project.
   * @param datasetId The ID of the dataset.
   * @return The location of the dataset.
   * @throws IOException If an I/O error occurs.
   */
  String getDatasetLocation(String projectId, String datasetId) throws IOException;

  /**
   * Submit a BigQuery job.
   *
   * @param query The query to submit.
   * @return The job that was submitted.
   */
  Job submitJob(String query);

  /**
   * Wait for a BigQuery job to complete and get the results.
   *
   * @param queryJob The job to wait for.
   * @return The results of the job.
   * @throws InterruptedException If the thread is interrupted while waiting.
   * @throws RuntimeException If the job fails.
   */
  TableResult waitAndGetJobResults(Job queryJob) throws InterruptedException, RuntimeException;

  /**
   * Get the schema fields of a BigQuery table.
   *
   * @param tableSpec The specification of the table.
   * @return The list of schema fields.
   * @throws IOException If an I/O error occurs.
   */
  List<TableFieldSchema> getTableSchemaFields(TableSpec tableSpec) throws IOException;

  /**
   * Patch the schema of a BigQuery table.
   *
   * @param tableSpec The specification of the table.
   * @param updatedFields The list of updated schema fields.
   * @throws IOException If an I/O error occurs.
   */
  void patchTableSchema(TableSpec tableSpec, List<TableFieldSchema> updatedFields)
      throws IOException;

  /**
   * Patch the labels of a BigQuery table.
   *
   * @param tableSpec The specification of the table.
   * @param tableLabels The map of labels to patch.
   * @throws IOException If an I/O error occurs.
   */
  void patchTableLabels(TableSpec tableSpec, Map<String, String> tableLabels) throws IOException;

  /**
   * Patch the schema and labels of a BigQuery table.
   *
   * @param tableSpec The specification of the table.
   * @param updatedFields The list of updated schema fields.
   * @param tableLabels The map of labels to patch.
   * @throws IOException If an I/O error occurs.
   */
  void patchTable(
      TableSpec tableSpec, List<TableFieldSchema> updatedFields, Map<String, String> tableLabels)
      throws IOException;

  /**
   * Get the number of rows in a BigQuery table.
   *
   * @param tableSpec The specification of the table.
   * @return The number of rows in the table.
   * @throws IOException If an I/O error occurs.
   */
  BigInteger getTableNumRows(TableSpec tableSpec) throws IOException;

  /**
   * Get the labels of a BigQuery table.
   *
   * @param tableSpec The specification of the table.
   * @return The map of labels.
   * @throws IOException If an I/O error occurs.
   */
  Map<String, String> getTableLabels(TableSpec tableSpec) throws IOException;

  /**
   * Check if a BigQuery table exists.
   *
   * @param tableSpec The specification of the table.
   * @return True if the table exists, false otherwise.
   */
  boolean tableExists(TableSpec tableSpec);

  /**
   * Set table labels to the ones supplied only. This is different from patchTableLabels that
   * appends and updates labels only but doesn't delete.
   *
   * @param tableSpec table to be updated
   * @param tableLabels table labels to be attached to the table
   */
  void overWriteTableLabels(TableSpec tableSpec, Map<String, String> tableLabels);
}
