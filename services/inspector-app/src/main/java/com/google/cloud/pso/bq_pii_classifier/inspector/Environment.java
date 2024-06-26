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
package com.google.cloud.pso.bq_pii_classifier.inspector;

import com.google.cloud.pso.bq_pii_classifier.functions.inspector.InspectorConfig;
import com.google.cloud.pso.bq_pii_classifier.functions.tagger.TaggerConfig;
import com.google.cloud.pso.bq_pii_classifier.helpers.Utils;
import com.google.gson.Gson;

import java.util.ArrayList;
import java.util.HashSet;

public class Environment {



    public InspectorConfig toConfig (){

        return new InspectorConfig(
                getProjectId(),
                getBqResultsDataset(),
                getBqResultsTable(),
                getDlpNotificationTopic(),
                getMinLikelihood(),
                Integer.parseInt(getMaxFindings()),
                Integer.parseInt(getSamplingMethod()),
                new Gson().fromJson(getDlpInspectionTemplatesIds(), ArrayList.class),
                getTableScanLimitsJsonConfig()
        );
    }


    public String getProjectId(){
        return Utils.getConfigFromEnv("PROJECT_ID", true);
    }

    public String getBqResultsDataset(){
        return Utils.getConfigFromEnv("BQ_RESULTS_DATASET", true);
    }

    public String getBqResultsTable(){
        return Utils.getConfigFromEnv("BQ_RESULTS_TABLE", true);
    }

    public String getDlpNotificationTopic(){
        return Utils.getConfigFromEnv("DLP_NOTIFICATION_TOPIC", true);
    }

    public String getMinLikelihood(){
        return Utils.getConfigFromEnv("MIN_LIKELIHOOD", true);
    }

    public String getMaxFindings(){
        return Utils.getConfigFromEnv("MAX_FINDINGS_PER_ITEM", true);
    }

    public String getSamplingMethod(){
        return Utils.getConfigFromEnv("SAMPLING_METHOD", true);
    }

    public String getDlpInspectionTemplatesIds(){
        return Utils.getConfigFromEnv("DLP_INSPECTION_TEMPLATES_IDS", true);
    }

    public String getTableScanLimitsJsonConfig(){
        return Utils.getConfigFromEnv("TABLE_SCAN_LIMITS_JSON_CONFIG", true);
    }

    public String getGcsFlagsBucket(){
        return Utils.getConfigFromEnv("GCS_FLAGS_BUCKET", true);
    }
}
