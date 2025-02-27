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

    private final String projectId;
    private final String computeRegionId;
    private final String dataRegionId;

    private final String dlpResultsDatasetName;

    private final String dlpResultsTableName;

    private final String dispatcherRunsTableName;
    private final String outputTopic;

    public GcsDispatcherConfig(String projectId,
                               String computeRegionId,
                               String dataRegionId,
                               String dlpResultsDatasetName,
                               String dlpResultsTableName,
                               String dispatcherRunsTableName,
                               String outputTopic
                            ) {
        this.projectId = projectId.toLowerCase();
        this.computeRegionId = computeRegionId.toLowerCase();
        this.dataRegionId = dataRegionId.toLowerCase();
        this.dlpResultsDatasetName = dlpResultsDatasetName.toLowerCase();
        this.dlpResultsTableName = dlpResultsTableName.toLowerCase();
        this.dispatcherRunsTableName = dispatcherRunsTableName.toLowerCase();
        this.outputTopic = outputTopic.toLowerCase();
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

    public String getDlpResultsDatasetName() {
        return dlpResultsDatasetName;
    }

    public String getDlpResultsTableName() {
        return dlpResultsTableName;
    }

    public String getDispatcherRunsTableName() {
        return dispatcherRunsTableName;
    }

    @Override
    public String toString() {
        return "GcsDispatcherConfig{" +
                "projectId='" + projectId + '\'' +
                ", computeRegionId='" + computeRegionId + '\'' +
                ", dataRegionId='" + dataRegionId + '\'' +
                ", dlpResultsDatasetName='" + dlpResultsDatasetName + '\'' +
                ", dlpResultsTableName='" + dlpResultsTableName + '\'' +
                ", dispatcherRunsTableName='" + dispatcherRunsTableName + '\'' +
                ", outputTopic='" + outputTopic + '\'' +
                '}';
    }
}
