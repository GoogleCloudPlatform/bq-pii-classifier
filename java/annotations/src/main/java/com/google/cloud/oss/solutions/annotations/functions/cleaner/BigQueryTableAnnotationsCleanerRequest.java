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

package com.google.cloud.oss.solutions.annotations.functions.cleaner;

import com.google.cloud.oss.solutions.annotations.entities.Operation;
import com.google.cloud.oss.solutions.annotations.entities.TableSpec;

public class BigQueryTableAnnotationsCleanerRequest extends Operation {

    private final TableSpec tableSpec;
    private final String tableLocation;
    private final String tagValue;

    public BigQueryTableAnnotationsCleanerRequest(String runId, String trackingId, TableSpec tableSpec, String bucketLocation, String tagValue) {
        super(runId, trackingId);
        this.tableSpec = tableSpec;
        this.tableLocation = bucketLocation;
        this.tagValue = tagValue;
    }

    public TableSpec getTableSpec() {
        return tableSpec;
    }

    public String getTableLocation() {
        return tableLocation;
    }

    public String getTagValue() {
        return tagValue;
    }

    @Override
    public String toString() {
        return "BigQueryTableAnnotationsCleanerRequest{" +
                "tableSpec=" + tableSpec +
                ", tableLocation='" + tableLocation + '\'' +
                ", tagValue='" + tagValue + '\'' +
                "} " + super.toString();
    }
}
