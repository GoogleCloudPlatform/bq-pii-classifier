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

package com.google.cloud.pso.bq_pii_classifier.services;

import com.google.cloud.dlp.v2.DlpServiceClient;
import com.google.privacy.dlp.v2.BigQueryTable;
import com.google.privacy.dlp.v2.CreateDlpJobRequest;
import com.google.privacy.dlp.v2.DlpJob;

import java.io.IOException;

public class DlpServiceImpl implements DlpService {

    DlpServiceClient dlpServiceClient;

    public DlpServiceImpl () throws IOException {
        dlpServiceClient = DlpServiceClient.create();
    }

    @Override
    public void shutDown(){
        dlpServiceClient.shutdown();
    }

    @Override
    public DlpJob submitJob(CreateDlpJobRequest createDlpJobRequest){
        return dlpServiceClient.createDlpJob(createDlpJobRequest);
    }

    @Override
    public DlpJob.JobState getJobState(String jobId){
        return dlpServiceClient.getDlpJob(jobId).getState();
    }
    @Override
    public BigQueryTable getInspectedTable(String jobId){
        return dlpServiceClient.getDlpJob(jobId)
                .getInspectDetails()
                .getRequestedOptions()
                .getJobConfig()
                .getStorageConfig()
                .getBigQueryOptions()
                .getTableReference();
    }
}
