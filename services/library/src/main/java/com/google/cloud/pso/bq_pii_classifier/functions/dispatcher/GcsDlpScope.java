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

package com.google.cloud.pso.bq_pii_classifier.functions.dispatcher;

import com.google.common.base.Objects;

public class GcsDlpScope {

    private final String projectsRegex;
    private final String bucketsRegex;

    public GcsDlpScope(String projectsRegex, String bucketsRegex) {
        this.projectsRegex = projectsRegex;
        this.bucketsRegex = bucketsRegex;
    }

    public String getProjectsRegex() {
        return projectsRegex;
    }

    public String getBucketsRegex() {
        return bucketsRegex;
    }

    @Override
    public String toString() {
        return "GcsScope{" +
                "projectsRegex='" + projectsRegex + '\'' +
                ", bucketsRegex='" + bucketsRegex + '\'' +
                '}';
    }

    @Override
    public boolean equals(Object o) {
        if (this == o) return true;
        if (o == null || getClass() != o.getClass()) return false;
        GcsDlpScope gcsDlpScope = (GcsDlpScope) o;
        return Objects.equal(projectsRegex, gcsDlpScope.projectsRegex) && Objects.equal(bucketsRegex, gcsDlpScope.bucketsRegex);
    }

    @Override
    public int hashCode() {
        return Objects.hashCode(projectsRegex, bucketsRegex);
    }
}
