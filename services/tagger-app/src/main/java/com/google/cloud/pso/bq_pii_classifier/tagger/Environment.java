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
package com.google.cloud.pso.bq_pii_classifier.tagger;

import com.google.cloud.pso.bq_pii_classifier.functions.tagger.TaggerConfig;
import com.google.cloud.pso.bq_pii_classifier.helpers.Utils;

import java.util.HashSet;

public class Environment {



    public TaggerConfig toConfig (){

        return new TaggerConfig(
                getProjectId(),
                getBqViewFieldsFindings(),
                new HashSet<>(
                        Utils.tokenize(getTaxonomies(), ",", true)),
                getIsDryRun()
        );
    }

    public String getProjectId(){
        return Utils.getConfigFromEnv("PROJECT_ID", true);
    }

    public String getBqViewFieldsFindings(){
        return Utils.getConfigFromEnv("BQ_VIEW_FIELDS_FINDINGS_SPEC", true);
    }

    public String getTaxonomies(){
        return Utils.getConfigFromEnv("TAXONOMIES", true);
    }

    public Boolean getIsDryRun(){
        return Boolean.valueOf(Utils.getConfigFromEnv("IS_DRY_RUN", true));
    }

}
