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

package com.google.cloud.pso.bq_pii_classifier.functions.tagger;

import com.google.cloud.pso.bq_pii_classifier.entities.InfoTypeInfo;

import java.util.Map;
import java.util.Set;

public class TaggerConfig {
    private final String projectId;
    private final Set<String> appOwnedTaxonomies;
    private final Boolean isDryRunTags;
    private final Boolean isDryRunLabels;
    private final Map<String, InfoTypeInfo> infoTypeMap;
    private final String existingLabelsRegex;

    public TaggerConfig(String projectId,
                        Set<String> appOwnedTaxonomies,
                        Boolean isDryRunTags,
                        Boolean isDryRunLabels,
                        Map<String, InfoTypeInfo> infoTypeMap,
                        String existingLabelsRegex
                        ) {
        this.projectId = projectId;
        this.appOwnedTaxonomies = appOwnedTaxonomies;
        this.isDryRunTags = isDryRunTags;
        this.isDryRunLabels = isDryRunLabels;
        this.infoTypeMap = infoTypeMap;
        this.existingLabelsRegex = existingLabelsRegex;
    }

    public  Set<String> getAppOwnedTaxonomies() {
        return appOwnedTaxonomies;
    }

    public Boolean isDryRunTags() {
        return isDryRunTags;
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

    public String getExistingLabelsRegex() {
        return existingLabelsRegex;
    }

    @Override
    public String toString() {
        return "TaggerConfig{" +
                "projectId='" + projectId + '\'' +
                ", appOwnedTaxonomies=" + appOwnedTaxonomies +
                ", isDryRunTags=" + isDryRunTags +
                ", isDryRunLabels=" + isDryRunLabels +
                ", infoTypeMap=" + infoTypeMap +
                ", existingLabelsRegex=" + existingLabelsRegex +
                '}';
    }
}
