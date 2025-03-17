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
package com.google.cloud.pso.bq_pii_classifier.apps.bq_tagger;

import com.google.cloud.pso.bq_pii_classifier.entities.InfoTypeInfo;
import com.google.cloud.pso.bq_pii_classifier.functions.tagger.DatasetDomainMapKey;
import com.google.cloud.pso.bq_pii_classifier.functions.tagger.InfoTypePolicyTagMapKey;
import com.google.cloud.pso.bq_pii_classifier.functions.tagger.InfoTypePolicyTagMapValue;
import com.google.cloud.pso.bq_pii_classifier.functions.tagger.TaggerConfig;
import com.google.cloud.pso.bq_pii_classifier.helpers.Utils;
import com.google.common.reflect.TypeToken;
import com.google.gson.Gson;

import java.lang.reflect.Type;
import java.util.*;

public class Environment {

    public TaggerConfig toConfig (){
        return new TaggerConfig(
                getProjectId(),
                new HashSet<>(Utils.tokenize(getTaxonomies(), ",", true)),
                getIsDryRunTags(),
                getIsDryRunLabels(),
                getInfoTypeMap(),
                getExistingLabelsRegex(),
                getDlpParent(),
                getPromoteDlpOtherMatches(),
                getInfoTypePolicyTagMap(),
                getProjectDomainMap(),
                getDatasetDomainMap(),
                getDefaultDomainName()
        );
    }

    public String getProjectId(){
        return Utils.getConfigFromEnv("PROJECT_ID", true);
    }

    public String getTaxonomies(){
        return Utils.getConfigFromEnv("TAXONOMIES", true);
    }

    public Boolean getIsDryRunTags(){
        return Utils.parseBooleanOrFail(Utils.getConfigFromEnv("IS_DRY_RUN_TAGS", true));
    }

    public Boolean getIsDryRunLabels(){
        return Utils.parseBooleanOrFail(Utils.getConfigFromEnv("IS_DRY_RUN_LABELS", true));
    }

    public String getGcsFlagsBucket(){
        return Utils.getConfigFromEnv("GCS_FLAGS_BUCKET", true);
    }

    public Map<String, InfoTypeInfo> getInfoTypeMap(){
        return InfoTypeInfo.fromJsonMap(Utils.getConfigFromEnv("INFO_TYPE_MAP", true));
    }

    public String getDefaultDomainName(){
        return Utils.getConfigFromEnv("DEFAULT_DOMAIN_NAME", true);
    }

    public String getExistingLabelsRegex(){
        return Utils.getConfigFromEnv("EXISTING_LABELS_REGEX", true);
    }

    public String getDlpParent(){
        return Utils.getConfigFromEnv("DLP_PARENT", true);
    }

    public Boolean getPromoteDlpOtherMatches () {
        return Utils.parseBooleanOrFail(Utils.getConfigFromEnv("PROMOTE_DLP_OTHER_MATCHES", true));
    }

    public Map<InfoTypePolicyTagMapKey, InfoTypePolicyTagMapValue> getInfoTypePolicyTagMap(){
        String json = Utils.getConfigFromEnv("INFO_TYPE_POLICY_TAG_MAP", true);

        Gson gson = new Gson();
        Type listType = new TypeToken<List<Map<String, String>>>() {}.getType();
        List<Map<String, String>> dataList = gson.fromJson(json, listType);

        Map<InfoTypePolicyTagMapKey, InfoTypePolicyTagMapValue> resultMap = new HashMap<>();

        for (Map<String, String> item : dataList) {
            resultMap.put(new InfoTypePolicyTagMapKey(
                    item.get("info_type"),
                    item.get("region"),
                    item.get("domain")
            ), new InfoTypePolicyTagMapValue(
                    item.get("policy_tag_id"),
                    item.get("classification")
            ));
        }
        return  resultMap;
    }

    public Map<String, String> getProjectDomainMap(){
        String json = Utils.getConfigFromEnv("PROJECT_DOMAIN_MAP", true);

        Gson gson = new Gson();
        Type listType = new TypeToken<List<Map<String, String>>>() {}.getType();
        List<Map<String, String>> dataList = gson.fromJson(json, listType);

        Map<String, String> resultMap = new HashMap<>();

        for (Map<String, String> item : dataList) {
            resultMap.put(item.get("project"), item.get("domain"));
        }
        return  resultMap;
    }

    public Map<DatasetDomainMapKey, String> getDatasetDomainMap(){
        String json = Utils.getConfigFromEnv("DATASET_DOMAIN_MAP", true);

        Gson gson = new Gson();
        Type listType = new TypeToken<List<Map<String, String>>>() {}.getType();
        List<Map<String, String>> dataList = gson.fromJson(json, listType);

        Map<DatasetDomainMapKey, String> resultMap = new HashMap<>();

        for (Map<String, String> item : dataList) {
            resultMap.put(
                    new DatasetDomainMapKey(
                            item.get("project"),
                            item.get("dataset")),
                    item.get("domain"));
        }
        return  resultMap;
    }
}


