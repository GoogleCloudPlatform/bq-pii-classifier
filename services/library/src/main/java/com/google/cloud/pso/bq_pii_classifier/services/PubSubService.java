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

import com.google.cloud.pso.bq_pii_classifier.entities.JsonMessage;

import java.io.IOException;
import java.util.List;

public interface PubSubService {

    //public PubSubPublishResults publishMessages(String projectId, String topicId, List<String> messages) throws IOException, InterruptedException;

    public PubSubPublishResults publishTableOperationRequests(String projectId, String topicId, List<JsonMessage> messages) throws IOException, InterruptedException;
}
