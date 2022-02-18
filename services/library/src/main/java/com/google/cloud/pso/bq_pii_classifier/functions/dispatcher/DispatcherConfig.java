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

public class DispatcherConfig {

    private String projectId;
    private String computeRegionId;
    private String dataRegionId;
    private String outputTopic;

    public DispatcherConfig(String projectId, String computeRegionId, String dataRegionId, String outputTopic) {
        this.projectId = projectId;
        this.computeRegionId = computeRegionId;
        this.dataRegionId = dataRegionId;
        this.outputTopic = outputTopic;
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

    @Override
    public String toString() {
        return "DispatcherConfig{" +
                "projectId='" + projectId + '\'' +
                ", computeRegionId='" + computeRegionId + '\'' +
                ", dataRegionId='" + dataRegionId + '\'' +
                ", outputTopic='" + outputTopic + '\'' +
                '}';
    }
}
