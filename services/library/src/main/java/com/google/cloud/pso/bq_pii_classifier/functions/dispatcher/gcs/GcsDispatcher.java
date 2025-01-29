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

import com.google.cloud.pso.bq_pii_classifier.entities.*;
import com.google.cloud.pso.bq_pii_classifier.functions.tagger.gcs.GcsTaggerRequest;
import com.google.cloud.pso.bq_pii_classifier.helpers.LoggingHelper;
import com.google.cloud.pso.bq_pii_classifier.helpers.TrackingHelper;
import com.google.cloud.pso.bq_pii_classifier.services.pubsub.FailedPubSubMessage;
import com.google.cloud.pso.bq_pii_classifier.services.pubsub.PubSubPublishResults;
import com.google.cloud.pso.bq_pii_classifier.services.pubsub.PubSubService;
import com.google.cloud.pso.bq_pii_classifier.services.pubsub.SuccessPubSubMessage;
import com.google.cloud.pso.bq_pii_classifier.services.scan.gcs.GcsScanner;
import com.google.cloud.pso.bq_pii_classifier.services.set.PersistentSet;
import java.io.IOException;
import java.util.ArrayList;
import java.util.List;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

public class GcsDispatcher {

  private static final Integer functionNumber = 1;

  private final LoggingHelper logger;
  private PubSubService pubSubService;

  private GcsScanner scanner;
  private GcsDispatcherConfig config;
  private PersistentSet persistentSet;
  private String persistentSetObjectPrefix;
  private String runId;

  public GcsDispatcher(
          GcsDispatcherConfig config,
          PubSubService pubSubService,
          GcsScanner scanner,
          PersistentSet persistentSet,
          String persistentSetObjectPrefix,
          String runId) {

    this.config = config;
    this.pubSubService = pubSubService;
    this.scanner = scanner;
    this.persistentSet = persistentSet;
    this.persistentSetObjectPrefix = persistentSetObjectPrefix;
    this.runId = runId;

    logger =
            new LoggingHelper(
                    GcsDispatcher.class.getSimpleName(), functionNumber, config.getProjectId());
  }

  public PubSubPublishResults execute(GcsScope scope, String pubSubMessageId)
          throws IOException, NonRetryableApplicationException, InterruptedException {

    /**
     * Check if we already processed this pubSubMessageId before to avoid re-running the dispatcher
     * (and the whole process) in case we have unexpected errors with PubSub re-sending the message.
     * This is an extra measure to avoid unnecessary cost. We do that by keeping simple flag files
     * in GCS with the pubSubMessageId as file name.
     */
    String flagFileName = String.format("%s/%s", persistentSetObjectPrefix, pubSubMessageId);
    if (persistentSet.contains(flagFileName)) {
      // log error and ACK and return
      String msg =
              String.format(
                      "PubSub message ID '%s' has been processed before by the dispatcher. The message should be ACK to PubSub to stop retries. Please investigate further why the message was retried in the first place.",
                      pubSubMessageId);
      throw new NonRetryableApplicationException(msg);
    } else {
      logger.logInfoWithTracker(
              runId,
              String.format("Persisting processing key for PubSub message ID %s", pubSubMessageId));
      persistentSet.add(flagFileName);
    }

    // initialize Tagger requests to be published based on the discovered profiles
    List<JsonMessage> pubSubMessagesToPublish = new ArrayList<>();

    // initialize counters for logging
    long allProfilesCount = 0;
    long noInfoTypesCount = 0;
    long noMatchProjectsRegex = 0;
    long noMatchBucketsRegex = 0;

    // compile regex for re-use to filter out profiles that is not in scope of this run
    Pattern projectsRegex = Pattern.compile(scope.getProjectsRegex());
    Pattern bucketsRegex = Pattern.compile(scope.getBucketsRegex());

    // get file store profiles from all supported source data regions
    for (String dataSourceRegion : scope.getSourceDataRegions()) {

      // get file store profiles for bucket in that region
      List<GcsDlpProfileSummary> profileSummaries =
              scanner.getGcsDlpProfiles(config.getDlpConfigParent(), dataSourceRegion);

      allProfilesCount += profileSummaries.size();


      // unpack each profile and check if it should be added as a tagger request
      for (GcsDlpProfileSummary profileSummary : profileSummaries) {

        Matcher projectsRegexMatcher = projectsRegex.matcher(profileSummary.getProjectId());
        Matcher bucketsRegexMatcher = bucketsRegex.matcher(profileSummary.getBucketName());

        if(!profileSummary.hasInfoTypes()){
          noInfoTypesCount += 1;
        }
        if(!projectsRegexMatcher.matches()){
          noMatchProjectsRegex += 1;
        }
        if(!bucketsRegexMatcher.matches()){
          noMatchBucketsRegex += 1;
        }

        // Create tagging requests for profiles with info types that are within scope
        if(profileSummary.hasInfoTypes() && projectsRegexMatcher.matches() && bucketsRegexMatcher.matches()){
          pubSubMessagesToPublish.add(
                  new GcsTaggerRequest(
                          runId,
                          TrackingHelper.generateTrackingId(runId, profileSummary.getBucketPath()),
                          profileSummary));
        }
      }
    }

    logger.logInfoWithTracker(runId,
            String.format("Listed %s total profiles: %s don't contain info types, %s don't match projects regex, %s don't match buckets regex, %s after applying filters will be sent for tagging. ",
                    allProfilesCount,
                    noInfoTypesCount,
                    noMatchProjectsRegex,
                    noMatchBucketsRegex,
                    pubSubMessagesToPublish.size() ));

    // Publish the list of tagging requests to PubSub
    PubSubPublishResults publishResults =
            pubSubService.publishTableOperationRequests(
                    config.getProjectId(), config.getOutputTopic(), pubSubMessagesToPublish);

    // this helps up in tracking and monitoring views to establish lineage across services/processing steps
    for (SuccessPubSubMessage msg : publishResults.getSuccessMessages()) {
      GcsTaggerRequest request = (GcsTaggerRequest) msg.getMsg();
      logger.logSuccessGcsDispatcherTrackingId(
              request.getRunId(),
              request.getTrackingId(),
              request.getGcsDlpProfileSummary().getBucketName(),
              request.getGcsDlpProfileSummary().getProjectId()
      );
    }

    for (FailedPubSubMessage msg : publishResults.getFailedMessages()) {
      GcsTaggerRequest request = (GcsTaggerRequest) msg.getMsg();
      String logMsg = String.format("Failed to publish these messages %s",
              msg.toString());
      logger.logWarnWithTracker(runId, logMsg);
      logger.logFailedGcsDispatcherEntityId(runId,
              request.getGcsDlpProfileSummary().getBucketName(),
              request.getGcsDlpProfileSummary().getProjectId(),
              msg.getException());
    }

    logger.logFunctionEnd(runId);

    return publishResults;
  }
}
