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


import com.google.api.core.ApiFuture;
import com.google.api.core.ApiFutureCallback;
import com.google.api.core.ApiFutures;
import com.google.api.gax.rpc.ApiException;
import com.google.cloud.pso.bq_pii_classifier.entities.JsonMessage;
import com.google.cloud.pubsub.v1.Publisher;
import com.google.common.util.concurrent.MoreExecutors;
import com.google.protobuf.ByteString;
import com.google.pubsub.v1.PubsubMessage;
import com.google.pubsub.v1.TopicName;

import java.io.IOException;
import java.util.ArrayList;
import java.util.List;
import java.util.concurrent.TimeUnit;

public class PubSubServiceImpl implements PubSubService {


    @Override
    public PubSubPublishResults publishTableOperationRequests(String projectId, String topicId, List<JsonMessage> messages)
            throws IOException, InterruptedException {

        List<SuccessPubSubMessage> successMessages = new ArrayList<>();
        List<FailedPubSubMessage> failedMessages = new ArrayList<>();

        Publisher publisher = null;
        try {
            TopicName topicName = TopicName.of(projectId, topicId);
            // Create a publisher instance with default settings bound to the topic
            publisher = Publisher.newBuilder(topicName).build();
            for (final JsonMessage msg : messages) {
                ByteString data = ByteString.copyFromUtf8(msg.toJsonString());
                PubsubMessage pubsubMessage = PubsubMessage.newBuilder().setData(data).build();

                // Once published, returns a server-assigned message id (unique within the topic)
                ApiFuture<String> future = publisher.publish(pubsubMessage);
                try{
                    // wait and retrieves results
                    String messageId = future.get();
                    successMessages.add(new SuccessPubSubMessage(msg, messageId));
                }catch (Exception ex){
                    failedMessages.add(new FailedPubSubMessage(msg, ex));
                }
            }

            return new PubSubPublishResults(successMessages, failedMessages);

        } finally {
            if (publisher != null) {
                // When finished with the publisher, shutdown to free up resources.
                publisher.shutdown();
                publisher.awaitTermination(1, TimeUnit.MINUTES);
            }
        }
    }
}
