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
    private String bqViewFieldsFindings;
    private Set<String> appOwnedTaxonomies;
    private Boolean isDryRun;

    public TaggerConfig(String projectId, String bqViewFieldsFindings, Set<String> appOwnedTaxonomies, Boolean isDryRun) {
        this.projectId = projectId;
        this.bqViewFieldsFindings = bqViewFieldsFindings;
        this.appOwnedTaxonomies = appOwnedTaxonomies;
        this.isDryRun = isDryRun;
    }

    public String getBqViewFieldsFindings() {
        return bqViewFieldsFindings;
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

    @Override
    public String toString() {
        return "TaggerConfig{" +
                "projectId='" + projectId + '\'' +
                ", bqViewFieldsFindings='" + bqViewFieldsFindings + '\'' +
                ", appOwnedTaxonomies=" + appOwnedTaxonomies +
                ", isDryRun=" + isDryRun +
                '}';
    }
}
