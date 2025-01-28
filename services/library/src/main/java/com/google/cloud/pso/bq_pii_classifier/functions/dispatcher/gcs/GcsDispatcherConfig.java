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

package com.google.cloud.pso.bq_pii_classifier.functions.dispatcher.gcs;

import com.google.cloud.pso.bq_pii_classifier.entities.SolutionMode;

public class GcsDispatcherConfig {

    private String projectId;
    private String computeRegionId;
    private String dataRegionId;

    private String dlpConfigParent;
    private String outputTopic;
    private SolutionMode solutionMode;

    public GcsDispatcherConfig(String projectId,
                               String computeRegionId,
                               String dataRegionId,
                               String dlpConfigParent,
                               String outputTopic,
                               SolutionMode solutionMode
                            ) {
        this.projectId = projectId.toLowerCase();
        this.computeRegionId = computeRegionId.toLowerCase();
        this.dataRegionId = dataRegionId.toLowerCase();
        this.outputTopic = outputTopic.toLowerCase();
        this.solutionMode = solutionMode;
        this.dlpConfigParent = dlpConfigParent;
    }



    public String getDataRegionId() {
        return dataRegionId;
    }

    public String getProjectId() {
        return projectId;
    }

    public String getComputeRegionId() {
        return computeRegionId;
    }

    public String getOutputTopic() {
        return outputTopic;
    }

    public SolutionMode getSolutionMode() {
        return solutionMode;
    }

    public String getDlpConfigParent() {
        return dlpConfigParent;
    }

    @Override
    public String toString() {
        return "DispatcherConfig{" +
                "projectId='" + projectId + '\'' +
                ", computeRegionId='" + computeRegionId + '\'' +
                ", dataRegionId='" + dataRegionId + '\'' +
                ", dlpConfigParent='" + dlpConfigParent + '\'' +
                ", outputTopic='" + outputTopic + '\'' +
                ", solutionMode=" + solutionMode +
                '}';
    }
}
