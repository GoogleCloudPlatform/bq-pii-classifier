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

package com.google.cloud.pso.bq_pii_classifier.entities;

import com.google.gson.Gson;

public class TableOperationRequest {

    private String tableSpec;
    private String runId;
    private String trackingId;

    public TableOperationRequest() {
    }

    public TableOperationRequest(String tableSpec, String runId, String trackingId) {
        this.tableSpec = tableSpec;
        this.runId = runId;
        this.trackingId = trackingId;
    }

    public String getTableSpec() {
        return tableSpec;
    }

    public String getRunId() {
        return runId;
    }

    public String getTrackingId() {
        return trackingId;
    }

    public void setTableSpec(String tableSpec) {
        this.tableSpec = tableSpec;
    }

    public void setRunId(String runId) {
        this.runId = runId;
    }

    public void setTrackingId(String trackingId) {
        this.trackingId = trackingId;
    }

    @Override
    public String toString() {
        return "TaggerRequest{" +
                "tableSpec='" + tableSpec + '\'' +
                ", runId='" + runId + '\'' +
                ", trackerId='" + trackingId + '\'' +
                '}';
    }

    public String toJsonString (){
        return new Gson().toJson(this);

    }
}
