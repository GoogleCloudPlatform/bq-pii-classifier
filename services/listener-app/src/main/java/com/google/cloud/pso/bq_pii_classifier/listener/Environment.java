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
package com.google.cloud.pso.bq_pii_classifier.listener;

import com.google.cloud.pso.bq_pii_classifier.functions.listener.Listener;
import com.google.cloud.pso.bq_pii_classifier.functions.listener.ListenerConfig;
import com.google.cloud.pso.bq_pii_classifier.functions.tagger.TaggerConfig;
import com.google.cloud.pso.bq_pii_classifier.helpers.Utils;

import java.util.HashSet;

public class Environment {



    public ListenerConfig toConfig (){

        return new ListenerConfig(
                getProjectId(),
                getRegionId(),
                getTaggerTopicId()
        );
    }

    public String getProjectId(){
        return Utils.getConfigFromEnv("PROJECT_ID", true);
    }

    public String getRegionId(){
        return Utils.getConfigFromEnv("REGION_ID", true);
    }

    public String getTaggerTopicId(){
        return Utils.getConfigFromEnv("TAGGER_TOPIC_ID", true);
    }


}
