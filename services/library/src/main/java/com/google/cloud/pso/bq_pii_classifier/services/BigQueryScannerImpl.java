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

import com.google.cloud.bigquery.BigQuery;
import com.google.cloud.bigquery.BigQueryOptions;
import com.google.cloud.bigquery.DatasetId;
import com.google.cloud.bigquery.TableDefinition;

import java.io.IOException;
import java.util.ArrayList;
import java.util.List;
import java.util.stream.Collectors;
import java.util.stream.StreamSupport;

public class BigQueryScannerImpl implements Scanner {

    private BigQuery bqService;

    public BigQueryScannerImpl() throws IOException {

        bqService = BigQueryOptions.getDefaultInstance().getService();
    }

    @Override
    public List<String> listTables(String projectId, String datasetId) {
        return StreamSupport.stream(bqService.listTables(DatasetId.of(projectId, datasetId)).iterateAll().spliterator(),
                false)
                .filter(t -> t.getDefinition().getType().equals(TableDefinition.Type.TABLE))
                .map(t -> String.format("%s.%s.%s", projectId, datasetId, t.getTableId().getTable()))
                .collect(Collectors.toCollection(ArrayList::new));
    }

    @Override
    public List<String> listDatasets(String projectId) {
        return StreamSupport.stream(bqService.listDatasets(projectId)
                        .iterateAll()
                        .spliterator(),
                false)
                .map(d -> String.format("%s.%s", projectId, d.getDatasetId().getDataset()))
                .collect(Collectors.toCollection(ArrayList::new));
    }
}
