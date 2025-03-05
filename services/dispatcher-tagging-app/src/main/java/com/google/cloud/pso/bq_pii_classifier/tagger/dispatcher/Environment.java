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
package com.google.cloud.pso.bq_pii_classifier.tagger.dispatcher;

import com.google.cloud.pso.bq_pii_classifier.functions.dispatcher.DispatcherConfig;
import com.google.cloud.pso.bq_pii_classifier.helpers.Utils;

public class Environment {

    public DispatcherConfig toConfig(){

        return new DispatcherConfig(
                getProjectId(),
                getTaggerTopic()
        );
    }

    public String getProjectId(){
        return Utils.getConfigFromEnv("PROJECT_ID", true);
    }
    public String getTaggerTopic() { return Utils.getConfigFromEnv("TAGGER_TOPIC", true); }

    public String getGcsFlagsBucket(){
        return Utils.getConfigFromEnv("GCS_FLAGS_BUCKET", true);
    }

    public String getSolutionDataset(){
        return Utils.getConfigFromEnv("SOLUTION_DATASET", true);
    }

    public String getDlpTableAuto(){
        return Utils.getConfigFromEnv("DLP_TABLE_AUTO", true);
    }
    public String getDispatcherRunsTable () {return Utils.getConfigFromEnv("DISPATCHER_RUNS_TABLE", true);}

}
