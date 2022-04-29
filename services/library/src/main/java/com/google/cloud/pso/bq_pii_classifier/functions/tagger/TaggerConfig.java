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

import java.util.Set;

public class TaggerConfig {

    private String projectId;
    private Set<String> appOwnedTaxonomies;
    private Boolean isDryRun;
    private String dlpDataset;
    private String dlpTableStandard;
    private String dlpTableAuto;
    private String configViewInfoTypePolicyTagsMap;
    private String configViewDatasetDomainMap;
    private String configViewProjectDomainMap;
    private Boolean isPromoteMixedTypes;
    private Boolean isAutoDlpMode;

    public TaggerConfig(String projectId,
                        Set<String> appOwnedTaxonomies,
                        String dlpDataset,
                        String dlpTableStandard,
                        String dlpTableAuto,
                        String configViewInfoTypePolicyTagsMap,
                        String configViewDatasetDomainMap,
                        String configViewProjectDomainMap,
                        Boolean isPromoteMixedTypes,
                        Boolean isAutoDlpMode,
                        Boolean isDryRun) {
        this.projectId = projectId;
        this.appOwnedTaxonomies = appOwnedTaxonomies;
        this.dlpDataset = dlpDataset;
        this.dlpTableStandard = dlpTableStandard;
        this.dlpTableAuto = dlpTableAuto;
        this.configViewInfoTypePolicyTagsMap = configViewInfoTypePolicyTagsMap;
        this.configViewDatasetDomainMap = configViewDatasetDomainMap;
        this.configViewProjectDomainMap = configViewProjectDomainMap;
        this.isPromoteMixedTypes = isPromoteMixedTypes;
        this.isAutoDlpMode = isAutoDlpMode;
        this.isDryRun = isDryRun;
    }

    public  Set<String> getAppOwnedTaxonomies() {
        return appOwnedTaxonomies;
    }

    public Boolean getDryRun() {
        return isDryRun;
    }

    public String getProjectId() {
        return projectId;
    }

    public String getDlpDataset() {
        return dlpDataset;
    }

    public String getConfigViewInfoTypePolicyTagsMap() {
        return configViewInfoTypePolicyTagsMap;
    }

    public String getConfigViewDatasetDomainMap() {
        return configViewDatasetDomainMap;
    }

    public String getConfigViewProjectDomainMap() {
        return configViewProjectDomainMap;
    }

    public String getDlpTableStandard() {
        return dlpTableStandard;
    }

    public String getDlpTableAuto() {
        return dlpTableAuto;
    }

    public Boolean isPromoteMixedTypes() {
        return isPromoteMixedTypes;
    }

    public Boolean isAutoDlpMode() {
        return isAutoDlpMode;
    }

    @Override
    public String toString() {
        return "TaggerConfig{" +
                "projectId='" + projectId + '\'' +
                ", appOwnedTaxonomies=" + appOwnedTaxonomies +
                ", isDryRun=" + isDryRun +
                ", dlpDataset='" + dlpDataset + '\'' +
                ", dlpTableStandard='" + dlpTableStandard + '\'' +
                ", dlpTableAuto='" + dlpTableAuto + '\'' +
                ", configViewInfoTypePolicyTagsMap='" + configViewInfoTypePolicyTagsMap + '\'' +
                ", configViewDatasetDomainMap='" + configViewDatasetDomainMap + '\'' +
                ", configViewProjectDomainMap='" + configViewProjectDomainMap + '\'' +
                ", isPromoteMixedTypes=" + isPromoteMixedTypes +
                ", isAutoDlpMode=" + isAutoDlpMode +
                '}';
    }
}
