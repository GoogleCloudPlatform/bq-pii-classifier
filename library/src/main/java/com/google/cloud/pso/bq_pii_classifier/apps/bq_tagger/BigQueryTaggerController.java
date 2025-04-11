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
package com.google.cloud.pso.bq_pii_classifier.apps.bq_tagger;

import com.google.cloud.pso.bq_pii_classifier.entities.*;
import com.google.cloud.pso.bq_pii_classifier.entities.dlp.DataProfilePubSubMessage;
import com.google.cloud.pso.bq_pii_classifier.functions.tagger.Tagger;
import com.google.cloud.pso.bq_pii_classifier.functions.tagger.TaggerRequest;
import com.google.cloud.pso.bq_pii_classifier.helpers.ControllerExceptionHelper;
import com.google.cloud.pso.bq_pii_classifier.helpers.LoggingHelper;
import com.google.cloud.pso.bq_pii_classifier.helpers.TrackingHelper;
import com.google.cloud.pso.bq_pii_classifier.services.bq.BigQueryServiceImpl;
import com.google.cloud.pso.bq_pii_classifier.services.findings.DlpFindingsReaderImpl;
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
public class BigQueryTaggerController {

  private static final Integer functionNumber = 3;
  private final LoggingHelper logger;
  private final Gson gson;
  private final Environment environment;

  public BigQueryTaggerController() {

    gson = new Gson();
    environment = new Environment();
    logger =
        new LoggingHelper(
            BigQueryTaggerController.class.getSimpleName(),
            functionNumber,
            environment.getProjectId());
  }

  public static void main(String[] args) {
    SpringApplication.run(BigQueryTaggerController.class, args);
  }

  @RequestMapping(value = "/tagging-dispatcher-handler", method = RequestMethod.POST)
  public ResponseEntity taggingDispatcherHandler(@RequestBody PubSubEvent requestBody) {

    TaggerRequest taggerRequest = null;

    try {

      if (requestBody == null || requestBody.getMessage() == null) {
        String msg = "Bad Request: invalid message format";
        logger.logSevereWithTracker(TrackingHelper.DEFAULT_TRACKING_ID, null, msg);
        throw new NonRetryableApplicationException("Request body or message is Null.");
      }

      String requestJsonString = requestBody.getMessage().dataToUtf8String();

      // remove any escape characters (e.g. from Terraform
      requestJsonString = requestJsonString.replace("\\", "");

      logger.logInfoWithTracker(
          TrackingHelper.DEFAULT_TRACKING_ID,
          null,
          String.format("Received payload: %s", requestJsonString));

      taggerRequest = gson.fromJson(requestJsonString, TaggerRequest.class);

      logger.logInfoWithTracker(
          taggerRequest.getTrackingId(),
          taggerRequest.getTargetTable().toSqlString(),
          String.format("Parsed Tagger Request from Dispatcher: %s", taggerRequest));

      Tagger tagger =
          new Tagger(
              environment.toConfig(),
              new BigQueryServiceImpl(),
              new DlpFindingsReaderImpl(),
              new GCSPersistentSetImpl(environment.getGcsFlagsBucket()),
              "tagger-flags");

      tagger.execute(taggerRequest, requestBody.getMessage().getMessageId());

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

    String trackingId = TrackingHelper.DEFAULT_TRACKING_ID;

    try {

      if (requestBody == null || requestBody.getMessage() == null) {
        String msg = "Bad Request: invalid message format";
        logger.logSevereWithTracker(trackingId, null, msg);
        throw new NonRetryableApplicationException("Request body or message is Null.");
      }

      String requestJsonString = requestBody.getMessage().dataToUtf8String();

      // remove any escape characters (e.g. from Terraform
      requestJsonString = requestJsonString.replace("\\", "");

      logger.logInfoWithTracker(
          trackingId, null, String.format("Received payload: %s", requestJsonString));

      byte[] data = requestBody.getMessage().getData();

      DataProfilePubSubMessage dataProfilePubSubMessage = DataProfilePubSubMessage.parseFrom(data);

      TableSpec targetTable =
          TableSpec.fromFullResource(dataProfilePubSubMessage.getProfile().getFullResource());

      String runId = TrackingHelper.generateOneTimeTaggingSuffixForBigQuery();
      trackingId = TrackingHelper.generateTrackingId(runId);

      logger.logInfoWithTracker(
          trackingId,
          targetTable.toSqlString(),
          String.format("Parsed DataProfilePubSubMessage= '%s'", dataProfilePubSubMessage));

      Tagger tagger =
          new Tagger(
              environment.toConfig(),
              new BigQueryServiceImpl(),
              new DlpFindingsReaderImpl(),
              new GCSPersistentSetImpl(environment.getGcsFlagsBucket()),
              "tagger-flags");

      tagger.execute(
          runId, trackingId, requestBody.getMessage().getMessageId(), dataProfilePubSubMessage);

      return new ResponseEntity("Process completed successfully.", HttpStatus.OK);
    } catch (Exception e) {
      return ControllerExceptionHelper.handleException(e, logger, trackingId);
    }
  }
}
