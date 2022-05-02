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
import java.util.Set;

public class Environment {



    public TaggerConfig toConfig (){
        return new TaggerConfig(
                getProjectId(),
                new HashSet<>(
                        Utils.tokenize(getTaxonomies(), ",", true)),
                getDlpDataset(),
                getDlpTableStandard(),
                getDlpTableAuto(),
                getConfigViewInfoTypePolicyTagsMap(),
                getConfigViewDatasetDomainMap(),
                getConfigViewProjectDomainMap(),
                getPromoteMixedTypes(),
                getIsAutoDlpMode(),
                getIsDryRun()
        );
    }

    public String getProjectId(){
        return Utils.getConfigFromEnv("PROJECT_ID", true);
    }

    public String getTaxonomies(){
        return Utils.getConfigFromEnv("TAXONOMIES", true);
    }

    public Boolean getIsDryRun(){
        return Boolean.valueOf(Utils.getConfigFromEnv("IS_DRY_RUN", true));
    }

    public String getGcsFlagsBucket(){
        return Utils.getConfigFromEnv("GCS_FLAGS_BUCKET", true);
    }

    public String getDlpDataset(){
        return Utils.getConfigFromEnv("DLP_DATASET", true);
    }

    public String getDlpTableStandard(){
        return Utils.getConfigFromEnv("DLP_TABLE_STANDARD", true);
    }

    public String getDlpTableAuto(){
        return Utils.getConfigFromEnv("DLP_TABLE_AUTO", true);
    }

    public String getConfigViewInfoTypePolicyTagsMap(){
        return Utils.getConfigFromEnv("VIEW_INFOTYPE_POLICYTAGS_MAP", true);
    }

    public String getConfigViewDatasetDomainMap(){
        return Utils.getConfigFromEnv("VIEW_DATASET_DOMAIN_MAP", true);
    }

    public String getConfigViewProjectDomainMap(){
        return Utils.getConfigFromEnv("VIEW_PROJECT_DOMAIN_MAP", true);
    }

    public Boolean getPromoteMixedTypes(){
        return Boolean.valueOf(Utils.getConfigFromEnv("PROMOTE_MIXED_TYPES", true));
    }

    public Boolean getIsAutoDlpMode(){
        return Boolean.valueOf(Utils.getConfigFromEnv("IS_AUTO_DLP_MODE", true));
    }

}
