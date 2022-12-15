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

import com.google.cloud.pso.bq_pii_classifier.entities.DispatcherType;
import com.google.cloud.pso.bq_pii_classifier.entities.SolutionMode;

import java.util.List;

public class DispatcherConfig {

    private String projectId;
    private String computeRegionId;
    private String dataRegionId;
    private String outputTopic;
    private DispatcherType dispatcherType;
    private SolutionMode solutionMode;

    private List<String> dlpInspectionTemplatesIds;

    public DispatcherConfig(String projectId,
                            String computeRegionId,
                            String dataRegionId,
                            String outputTopic,
                            DispatcherType dispatcherType,
                            SolutionMode solutionMode,
                            List<String> dlpInspectionTemplatesIds
                            ) {
        this.projectId = projectId;
        this.computeRegionId = computeRegionId;
        this.dataRegionId = dataRegionId;
        this.outputTopic = outputTopic;
        this.dispatcherType = dispatcherType;
        this.solutionMode = solutionMode;
        this.dlpInspectionTemplatesIds = dlpInspectionTemplatesIds;
    }

    public DispatcherType getDispatcherType() {
        return dispatcherType;
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

    public List<String> getDlpInspectionTemplatesIds() {
        return dlpInspectionTemplatesIds;
    }

    @Override
    public String toString() {
        return "DispatcherConfig{" +
                "projectId='" + projectId + '\'' +
                ", computeRegionId='" + computeRegionId + '\'' +
                ", dataRegionId='" + dataRegionId + '\'' +
                ", outputTopic='" + outputTopic + '\'' +
                ", dispatcherType=" + dispatcherType +
                ", solutionMode=" + solutionMode +
                ", dlpInspectionTemplatesIds=" + dlpInspectionTemplatesIds +
                '}';
    }
}
