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

package com.google.cloud.pso.bq_pii_classifier.functions.dispatcher;

import java.util.ArrayList;
import java.util.List;
import java.util.Objects;
import java.util.stream.Collectors;

public class BigQueryScope {

    private List<String> projectIncludeList;
    private List<String> datasetIncludeList;
    private List<String> datasetExcludeList;
    private List<String> tableExcludeList;


    public BigQueryScope() {
        this.projectIncludeList = new ArrayList<>();
        this.datasetIncludeList = new ArrayList<>();
        this.datasetExcludeList = new ArrayList<>();
        this.tableExcludeList = new ArrayList<>();
    }

    public BigQueryScope(List<String> projectIncludeList, List<String> datasetIncludeList, List<String> datasetExcludeList, List<String> tableExcludeList) {
        this.projectIncludeList = projectIncludeList.stream().map(String::toLowerCase).collect(Collectors.toList());
        this.datasetIncludeList = datasetIncludeList.stream().map(String::toLowerCase).collect(Collectors.toList());
        this.datasetExcludeList = datasetExcludeList.stream().map(String::toLowerCase).collect(Collectors.toList());
        this.tableExcludeList = tableExcludeList.stream().map(String::toLowerCase).collect(Collectors.toList());
    }

    public List<String> getProjectIncludeList() {
        return projectIncludeList;
    }

    public List<String> getDatasetIncludeList() {
        return datasetIncludeList;
    }

    public List<String> getDatasetExcludeList() {
        return datasetExcludeList;
    }


    public List<String> getTableExcludeList() {
        return tableExcludeList;
    }


    @Override
    public String toString() {
        return "BigQueryScope{" +
                "projectIncludeList=" + projectIncludeList +
                ", datasetIncludeList=" + datasetIncludeList +
                ", datasetExcludeList=" + datasetExcludeList +
                ", tableExcludeList=" + tableExcludeList +
                '}';
    }

    @Override
    public boolean equals(Object o) {
        if (this == o) return true;
        if (o == null || getClass() != o.getClass()) return false;
        BigQueryScope that = (BigQueryScope) o;
        return Objects.equals(projectIncludeList, that.projectIncludeList) &&
                Objects.equals(datasetIncludeList, that.datasetIncludeList) &&
                Objects.equals(datasetExcludeList, that.datasetExcludeList) &&
                Objects.equals(tableExcludeList, that.tableExcludeList);
    }

    @Override
    public int hashCode() {
        return Objects.hash(projectIncludeList, datasetIncludeList, datasetExcludeList, tableExcludeList);
    }
}
