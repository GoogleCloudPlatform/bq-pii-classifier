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

public class Operation implements JsonMessage {
    

    // entity key is table spec in case of Dispatcher to Inspector route
    // entity key is dlpJob name in case of Dispatcher to Tagger route
    private String entityKey;
    private String runId;
    private String trackingId;

    public Operation() {
    }

    public Operation(String entityKey, String runId, String trackingId) {
        this.entityKey = entityKey;
        this.runId = runId;
        this.trackingId = trackingId;
    }


    public String getEntityKey() {
        return entityKey;
    }

    public String getRunId() {
        return runId;
    }

    public String getTrackingId() {
        return trackingId;
    }

    @Override
    public String toString() {
        return "Operation{" +
                "entityKey='" + entityKey + '\'' +
                ", runId='" + runId + '\'' +
                ", trackingId='" + trackingId + '\'' +
                '}';
    }

    @Override
    public String toJsonString (){
        return new Gson().toJson(this);

    }
}
