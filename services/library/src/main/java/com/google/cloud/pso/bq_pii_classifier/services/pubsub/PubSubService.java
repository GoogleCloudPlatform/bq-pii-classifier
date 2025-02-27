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

import com.google.cloud.bigquery.TableResult;
import com.google.cloud.pso.bq_pii_classifier.entities.JsonMessage;
import com.google.cloud.pso.bq_pii_classifier.entities.NonRetryableApplicationException;
import com.google.cloud.pso.bq_pii_classifier.helpers.LoggingHelper;

import java.io.IOException;
import java.util.List;
import java.util.concurrent.ExecutionException;

public interface PubSubService {

  PubSubPublishResults publishTableOperationRequests(
      String projectId, String topicId, List<JsonMessage> messages)
      throws IOException, InterruptedException;

  public void publishBigQueryTableResults(
      TableResult bqTableResults,
      String pubSubProjectId,
      String pubSubTopic,
      String runId,
      LoggingHelper logger,
      long successMessagesIntervalForLogging)
      throws IOException,
          ExecutionException,
          InterruptedException,
          NonRetryableApplicationException;
}
