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
package com.google.cloud.pso.bq_pii_classifier.apps.gcs_tagger;

import com.google.cloud.pso.bq_pii_classifier.entities.GcsDlpProfileSummary;
import com.google.cloud.pso.bq_pii_classifier.entities.NonRetryableApplicationException;
import com.google.cloud.pso.bq_pii_classifier.entities.PubSubEvent;
import com.google.cloud.pso.bq_pii_classifier.entities.dlp.DataProfilePubSubMessage;
import com.google.cloud.pso.bq_pii_classifier.functions.tagger.gcs.GcsTagger;
import com.google.cloud.pso.bq_pii_classifier.functions.tagger.gcs.GcsTaggerRequest;
import com.google.cloud.pso.bq_pii_classifier.helpers.ControllerExceptionHelper;
import com.google.cloud.pso.bq_pii_classifier.helpers.LoggingHelper;
import com.google.cloud.pso.bq_pii_classifier.helpers.TrackingHelper;
import com.google.cloud.pso.bq_pii_classifier.helpers.Utils;
import com.google.cloud.pso.bq_pii_classifier.services.findings.DlpFindingsReaderImpl;
import com.google.cloud.pso.bq_pii_classifier.services.gcs.GcsServiceImpl;
import com.google.cloud.pso.bq_pii_classifier.services.set.GCSPersistentSetImpl;
import com.google.gson.Gson;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestMethod;
import org.springframework.web.bind.annotation.RestController;

@SpringBootApplication
@RestController
public class GcsTaggerController {

  private static final Integer functionNumber = 3;
  private final LoggingHelper logger;
  private final Gson gson;
  private final Environment environment;

  public GcsTaggerController() {

    gson = new Gson();
    environment = new Environment();
    logger =
        new LoggingHelper(
            GcsTaggerController.class.getSimpleName(), functionNumber, environment.getProjectId());
  }

  public static void main(String[] args) {
    SpringApplication.run(GcsTaggerController.class, args);
  }

  // The pubsub message could come from different sources with different formats
  // 1. From GCS Tagging Dispatcher as GcsTaggerRequest serialized json
  // 2. From GCS Auto DLP notification as "DataProfilePubSubMessage" proto

  @RequestMapping(value = "/tagging-dispatcher-handler", method = RequestMethod.POST)
  public ResponseEntity taggingDispatcherHandler(@RequestBody PubSubEvent requestBody) {

    GcsTaggerRequest taggerRequest = null;

    try {

      if (requestBody == null || requestBody.getMessage() == null) {
        String msg = "Bad Request: invalid message format";
        logger.logSevereWithTracker(TrackingHelper.DEFAULT_TRACKING_ID, null, msg);
        throw new NonRetryableApplicationException("Request body or message is Null.");
      }

      String requestJsonString = requestBody.getMessage().dataToUtf8String();
      // try to parse as GcsTaggerRequest as sent from the Tagging Dispatcher Service
      taggerRequest = gson.fromJson(requestJsonString, GcsTaggerRequest.class);

      logger.logInfoWithTracker(
              taggerRequest.getTrackingId(),
              Utils.generateBucketEntityId(
                      taggerRequest.getGcsDlpProfileSummary().getProjectId(),
                      taggerRequest.getGcsDlpProfileSummary().getBucketName()),
              String.format("Parsed Request from GCS Tagging Dispatcher: '%s'", taggerRequest));

      GcsTagger gcsTagger =
          new GcsTagger(
              environment.toConfig(),
              new DlpFindingsReaderImpl(),
              new GcsServiceImpl(),
              new GCSPersistentSetImpl(environment.getGcsFlagsBucket()),
              "gcs-tagger-flags");

      gcsTagger.execute(taggerRequest, requestBody.getMessage().getMessageId());

      return new ResponseEntity("Process completed successfully.", HttpStatus.OK);
    } catch (Exception e) {

      String trackingId =
          taggerRequest == null
              ? TrackingHelper.DEFAULT_TRACKING_ID
              : taggerRequest.getTrackingId();
      return ControllerExceptionHelper.handleException(e, logger, trackingId);
    }
  }

  @RequestMapping(value = "/dlp-discovery-service-handler", method = RequestMethod.POST)
  public ResponseEntity dlpDiscoveryServiceHandler(@RequestBody PubSubEvent requestBody) {

    GcsTaggerRequest taggerRequest = null;

    try {

      if (requestBody == null || requestBody.getMessage() == null) {
        String msg = "Bad Request: invalid message format";
        logger.logSevereWithTracker(TrackingHelper.DEFAULT_TRACKING_ID, null, msg);
        throw new NonRetryableApplicationException("Request body or message is Null.");
      }

      // try to parse as GcsTaggerRequest as sent from the Tagging Dispatcher Service
      taggerRequest = getTaggerRequestFromDlpNotification(requestBody);

      GcsTagger gcsTagger =
              new GcsTagger(
                      environment.toConfig(),
                      new DlpFindingsReaderImpl(),
                      new GcsServiceImpl(),
                      new GCSPersistentSetImpl(environment.getGcsFlagsBucket()),
                      "gcs-tagger-flags");

      gcsTagger.execute(taggerRequest, requestBody.getMessage().getMessageId());

      return new ResponseEntity("Process completed successfully.", HttpStatus.OK);
    } catch (Exception e) {

      String trackingId =
              taggerRequest == null
                      ? TrackingHelper.DEFAULT_TRACKING_ID
                      : taggerRequest.getTrackingId();
      return ControllerExceptionHelper.handleException(e, logger, trackingId);
    }
  }

  private GcsTaggerRequest getTaggerRequestFromDlpNotification(PubSubEvent event) throws NonRetryableApplicationException {

      try {
        byte[] data = event.getMessage().getData();

        DataProfilePubSubMessage dataProfilePubSubMessage =
            DataProfilePubSubMessage.parseFrom(data);

        if (dataProfilePubSubMessage.hasFileStoreProfile()) {

          String fileStoreProfileName = dataProfilePubSubMessage.getFileStoreProfile().getName();
          String fileStorePath = dataProfilePubSubMessage.getFileStoreProfile().getFileStorePath();
          String runId = TrackingHelper.generateOneTimeTaggingSuffixForGcs();
          String trackingId = TrackingHelper.generateTrackingId(runId);

          logger.logInfoWithTracker(
              trackingId,
              null,
              String.format(
                  "Parsed message from Auto DLP DataProfilePubSubMessage= '%s'",
                  dataProfilePubSubMessage));

          // CASE 2: GcsTaggerRequest computed from GCS Auto DLP PubSub message proto
          return new GcsTaggerRequest(
              runId, trackingId, new GcsDlpProfileSummary(fileStoreProfileName, fileStorePath));
        } else {
          throw new NonRetryableApplicationException(
              "Auto DLP message doesn't contain a file store profile");
        }

      } catch (Exception ex) {

        throw new NonRetryableApplicationException(
            String.format(
                "Couldn't parse PubSub event as Proto: %s : %s",
                ex.getClass().getSimpleName(), ex.getMessage()));
      }
    }
}
