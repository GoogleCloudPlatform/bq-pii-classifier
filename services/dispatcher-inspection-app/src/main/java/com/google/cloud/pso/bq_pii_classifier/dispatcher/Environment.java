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

package com.google.cloud.pso.bq_pii_classifier.dispatcher;

import com.google.cloud.pso.bq_pii_classifier.entities.DispatcherType;
import com.google.cloud.pso.bq_pii_classifier.entities.SolutionMode;
import com.google.cloud.pso.bq_pii_classifier.functions.dispatcher.DispatcherConfig;
import com.google.cloud.pso.bq_pii_classifier.helpers.Utils;
import com.google.gson.Gson;

import java.util.ArrayList;

public class Environment {

    public DispatcherConfig toConfig(){
        return new DispatcherConfig(
                getProjectId(),
                getComputeRegionId(),
                getDataRegionId(),
                new Gson().fromJson(getSourceDataRegions().toLowerCase(), ArrayList.class),
                getInspectionTopic(),
                DispatcherType.INSPECTION,
                SolutionMode.STANDARD_DLP,
                Utils.parseJsonToMap(getDlpInspectionTemplatesIds(), "region", "ids")
        );
    }

    public String getProjectId(){
        return Utils.getConfigFromEnv("PROJECT_ID", true);
    }

    public String getComputeRegionId(){
        return Utils.getConfigFromEnv("COMPUTE_REGION_ID", true);
    }

    public String getDataRegionId(){
        return Utils.getConfigFromEnv("DATA_REGION_ID", true);
    }

    public String getSourceDataRegions(){
        return Utils.getConfigFromEnv("SOURCE_DATA_REGIONS", true);
    }

    public String getInspectionTopic() { return Utils.getConfigFromEnv("INSPECTION_TOPIC", true); }

    public String getGcsFlagsBucket(){
        return Utils.getConfigFromEnv("GCS_FLAGS_BUCKET", true);
    }

    public String getDlpInspectionTemplatesIds(){
        return Utils.getConfigFromEnv("DLP_INSPECTION_TEMPLATES_IDS", true);
    }
}
