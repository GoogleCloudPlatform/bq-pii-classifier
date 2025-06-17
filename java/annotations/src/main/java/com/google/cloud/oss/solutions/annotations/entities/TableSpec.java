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

package com.google.cloud.oss.solutions.annotations.entities;

import com.google.cloud.bigquery.TableId;
import com.google.cloud.oss.solutions.annotations.helpers.Utils;
import java.util.List;
import javax.annotation.Nullable;

/** Value object to represent a BigQuery table. */
public record TableSpec(@Nullable String folder, String project, String dataset, String table) {

  public TableSpec(String project, String dataset, String table) {
    this(null, project, dataset, table);
  }

  // parse from "project.dataset.table" format
  public static TableSpec fromSqlString(String sqlTableId) {
    List<String> targetTableSpecs = Utils.tokenize(sqlTableId, ".", true);
    return new TableSpec(targetTableSpecs.get(0), targetTableSpecs.get(1), targetTableSpecs.get(2));
  }

  // parse from
  // "//bigquery.googleapis.com/projects/#project_name/datasets/#dataset_name/tables/#table_name>"
  public static TableSpec fromFullResource(String fullResource) {
    List<String> tokens = Utils.tokenize(fullResource, "/", true);
    return new TableSpec(tokens.get(2), tokens.get(4), tokens.get(6));
  }

  public String toSqlString() {
    return String.format("%s.%s.%s", project, dataset, table);
  }

  public TableId toTableId() {
    return TableId.of(project, dataset, table);
  }

  @Override
  public String toString() {
    return "TableSpec{"
        + "folder='"
        + folder
        + '\''
        + ", project='"
        + project
        + '\''
        + ", dataset='"
        + dataset
        + '\''
        + ", table='"
        + table
        + '\''
        + '}';
  }
}
