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

package com.google.cloud.pso.bq_pii_classifier.functions.inspector;

import java.util.List;

public class InspectorConfig {

    private String projectId;
    private String bqResultsDataset;
    private String bqResultsTable;
    private String dlpNotificationTopic;
    private String minLikelihood;
    private Integer maxFindings;
    private Integer samplingMethod;
    private List<String> dlpInspectionTemplatesIds;
    private String tableScanLimitsJsonConfig;

    public InspectorConfig(String projectId, String bqResultsDataset, String bqResultsTable, String dlpNotificationTopic, String minLikelihood, Integer maxFindings, Integer samplingMethod, List<String> dlpInspectionTemplatesIds, String tableScanLimitsJsonConfig) {
        this.projectId = projectId;
        this.bqResultsDataset = bqResultsDataset;
        this.bqResultsTable = bqResultsTable;
        this.dlpNotificationTopic = dlpNotificationTopic;
        this.minLikelihood = minLikelihood;
        this.maxFindings = maxFindings;
        this.samplingMethod = samplingMethod;
        this.dlpInspectionTemplatesIds = dlpInspectionTemplatesIds;
        this.tableScanLimitsJsonConfig = tableScanLimitsJsonConfig;
    }

    public String getProjectId() {
        return projectId;
    }

    public String getBqResultsDataset() {
        return bqResultsDataset;
    }

    public String getBqResultsTable() {
        return bqResultsTable;
    }

    public String getDlpNotificationTopic() {
        return dlpNotificationTopic;
    }

    public String getMinLikelihood() {
        return minLikelihood;
    }

    public Integer getMaxFindings() {
        return maxFindings;
    }

    public Integer getSamplingMethod() {
        return samplingMethod;
    }

    public List<String> getDlpInspectionTemplatesIds() {
        return dlpInspectionTemplatesIds;
    }

    public String getTableScanLimitsJsonConfig() {
        return tableScanLimitsJsonConfig;
    }

    @Override
    public String toString() {
        return "InspectorConfig{" +
                "projectId='" + projectId + '\'' +
                ", bqResultsDataset='" + bqResultsDataset + '\'' +
                ", bqResultsTable='" + bqResultsTable + '\'' +
                ", dlpNotificationTopic='" + dlpNotificationTopic + '\'' +
                ", minLikelihood='" + minLikelihood + '\'' +
                ", maxFindings='" + maxFindings + '\'' +
                ", samplingMethod='" + samplingMethod + '\'' +
                ", dlpInspectionTemplatesIds='" + dlpInspectionTemplatesIds + '\'' +
                ", tableScanLimitsJsonConfig='" + tableScanLimitsJsonConfig + '\'' +
                '}';
    }
}
