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
import java.util.Map;
import java.util.stream.Collectors;

public class DispatcherConfig {

    private String projectId;
    private String computeRegionId;
    private String dataRegionId;

    private List<String> sourceDataRegions;
    private String outputTopic;
    private DispatcherType dispatcherType;
    private SolutionMode solutionMode;
    private Map<String, List<String>> dlpInspectionTemplatesIdsPerRegion;

    public DispatcherConfig(String projectId,
                            String computeRegionId,
                            String dataRegionId,
                            List<String> sourceDataRegions,
                            String outputTopic,
                            DispatcherType dispatcherType,
                            SolutionMode solutionMode,
                            Map<String, List<String>> dlpInspectionTemplatesIdsPerRegion
                            ) {
        this.projectId = projectId.toLowerCase();
        this.computeRegionId = computeRegionId.toLowerCase();
        this.dataRegionId = dataRegionId.toLowerCase();
        this.sourceDataRegions = sourceDataRegions.stream().map(String::toLowerCase).collect(Collectors.toList());
        this.outputTopic = outputTopic.toLowerCase();
        this.dispatcherType = dispatcherType;
        this.solutionMode = solutionMode;
        this.dlpInspectionTemplatesIdsPerRegion = dlpInspectionTemplatesIdsPerRegion;
    }

    public DispatcherType getDispatcherType() {
        return dispatcherType;
    }

    public String getDataRegionId() {
        return dataRegionId;
    }

    public List<String> getSourceDataRegions() {
        return sourceDataRegions;
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

    public Map<String, List<String>> getDlpInspectionTemplatesIdsPerRegion() {
        return dlpInspectionTemplatesIdsPerRegion;
    }

    @Override
    public String toString() {
        return "DispatcherConfig{" +
                "projectId='" + projectId + '\'' +
                ", computeRegionId='" + computeRegionId + '\'' +
                ", dataRegionId='" + dataRegionId + '\'' +
                ", sourceDataRegions'" + sourceDataRegions + '\'' +
                ", outputTopic='" + outputTopic + '\'' +
                ", dispatcherType=" + dispatcherType +
                ", solutionMode=" + solutionMode +
                ", dlpInspectionTemplatesIds=" + dlpInspectionTemplatesIdsPerRegion +
                '}';
    }
}
