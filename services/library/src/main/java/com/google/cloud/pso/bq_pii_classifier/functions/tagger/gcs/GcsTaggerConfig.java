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

package com.google.cloud.pso.bq_pii_classifier.functions.tagger.gcs;

import com.google.cloud.pso.bq_pii_classifier.entities.InfoTypeInfo;
import java.util.Map;
import java.util.Set;

public class GcsTaggerConfig {

    private String projectId;
    private Boolean isDryRunLabels;
    private Map<String, InfoTypeInfo> infoTypeMap;

    public GcsTaggerConfig(String projectId,
                           Boolean isDryRunLabels,
                           Map<String, InfoTypeInfo> infoTypeMap
                        ) {
        this.projectId = projectId;
        this.isDryRunLabels = isDryRunLabels;
        this.infoTypeMap = infoTypeMap;
    }

    public Boolean isDryRunLabels() {
        return isDryRunLabels;
    }

    public String getProjectId() {
        return projectId;
    }

    public Map<String, InfoTypeInfo> getInfoTypeMap() {
        return infoTypeMap;
    }

    @Override
    public String toString() {
        return "GcsTaggerConfig{" +
                "projectId='" + projectId + '\'' +
                ", isDryRunLabels=" + isDryRunLabels +
                ", infoTypeMap=" + infoTypeMap +
                '}';
    }
}
