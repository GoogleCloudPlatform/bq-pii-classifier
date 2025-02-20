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
package com.google.cloud.pso.bq_pii_classifier.tagger.gcs;

import com.google.cloud.pso.bq_pii_classifier.entities.InfoTypeInfo;
import com.google.cloud.pso.bq_pii_classifier.functions.tagger.TaggerConfig;
import com.google.cloud.pso.bq_pii_classifier.functions.tagger.gcs.GcsTaggerConfig;
import com.google.cloud.pso.bq_pii_classifier.helpers.Utils;

import java.util.HashSet;
import java.util.Map;
import java.util.Set;

public class Environment {

    public GcsTaggerConfig toConfig (){
        return new GcsTaggerConfig(
                getProjectId(),
                getIsDryRunLabels(),
                getInfoTypeMap(),
                getExistingLabelsRegex()
        );
    }

    public String getProjectId(){
        return Utils.getConfigFromEnv("PROJECT_ID", true);
    }

    public Boolean getIsDryRunLabels(){
        return Boolean.valueOf(Utils.getConfigFromEnv("IS_DRY_RUN_LABELS", true));
    }

    public String getGcsFlagsBucket(){
        return Utils.getConfigFromEnv("GCS_FLAGS_BUCKET", true);
    }

    public Map<String, InfoTypeInfo> getInfoTypeMap(){
        return InfoTypeInfo.fromJsonMap(Utils.getConfigFromEnv("INFO_TYPE_MAP", true));
    }

    public String getExistingLabelsRegex(){
        return Utils.getConfigFromEnv("EXISTING_LABELS_REGEX", true);
    }


}
