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

package com.google.cloud.pso.bq_pii_classifier.services.pubsub;

import java.util.List;

public class PubSubPublishResults {

    private List<SuccessPubSubMessage> successMessages;
    private List<FailedPubSubMessage> failedMessages;

    public PubSubPublishResults(List<SuccessPubSubMessage> successMessages, List<FailedPubSubMessage> failedMessages) {
        this.successMessages = successMessages;
        this.failedMessages = failedMessages;
    }

    public List<SuccessPubSubMessage> getSuccessMessages() {
        return successMessages;
    }

    public List<FailedPubSubMessage> getFailedMessages() {
        return failedMessages;
    }

    @Override
    public String toString() {
        return "PubSubPublishResults{" +
                "successMessages=" + successMessages +
                ", failedMessages=" + failedMessages +
                '}';
    }
}
