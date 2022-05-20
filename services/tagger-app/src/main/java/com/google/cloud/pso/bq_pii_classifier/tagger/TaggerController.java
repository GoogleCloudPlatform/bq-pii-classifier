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
package com.google.cloud.pso.bq_pii_classifier.tagger;

import com.google.cloud.pso.bq_pii_classifier.entities.Operation;
import com.google.cloud.pso.bq_pii_classifier.entities.PubSubEvent;
import com.google.cloud.pso.bq_pii_classifier.entities.TableSpec;
import com.google.cloud.pso.bq_pii_classifier.entities.dlp.DataProfilePubSubMessage;
import com.google.cloud.pso.bq_pii_classifier.functions.tagger.Tagger;
import com.google.cloud.pso.bq_pii_classifier.helpers.ControllerExceptionHelper;
import com.google.cloud.pso.bq_pii_classifier.helpers.LoggingHelper;
import com.google.cloud.pso.bq_pii_classifier.entities.NonRetryableApplicationException;
import com.google.cloud.pso.bq_pii_classifier.helpers.TrackingHelper;
import com.google.cloud.pso.bq_pii_classifier.services.bq.BigQueryService;
import com.google.cloud.pso.bq_pii_classifier.services.bq.BigQueryServiceImpl;
import com.google.cloud.pso.bq_pii_classifier.services.findings.FindingsReader;
import com.google.cloud.pso.bq_pii_classifier.services.findings.FindingsReaderFactory;
import com.google.cloud.pso.bq_pii_classifier.services.set.GCSPersistentSetImpl;
import com.google.gson.Gson;
import com.google.protobuf.InvalidProtocolBufferException;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestMethod;

import java.util.Base64;

@SpringBootApplication(scanBasePackages = "com.google.cloud.pso.bq_pii_classifier")
@RestController
public class TaggerController {

    private final LoggingHelper logger;
    private static final Integer functionNumber = 3;
    private Gson gson;
    Environment environment;

    public TaggerController() {

        gson = new Gson();
        environment = new Environment();
        logger = new LoggingHelper(
                TaggerController.class.getSimpleName(),
                functionNumber,
                environment.getProjectId()
        );
    }

    @RequestMapping(value = "/", method = RequestMethod.POST)
    public ResponseEntity receiveMessage(@RequestBody PubSubEvent requestBody) {

        String defaultTrackingId = "0000000000000-z";
        Operation taggerRequest = null;

        try {

            if (requestBody == null || requestBody.getMessage() == null) {
                String msg = "Bad Request: invalid message format";
                logger.logSevereWithTracker(defaultTrackingId, msg);
                throw new NonRetryableApplicationException("Request body or message is Null.");
            }

            // The pubsub message could come from different sources with different formats
            // 1. From the Dispatcher as JSON encoded "Operation" object (in standard and auto-dlp modes)
            // 2. From Standard DLP inspection job notifications (PubSub Actions) as a string message with the DLP job name
            // 3. From Auto DLP notifications (PubSub Actions) as Protobuf encoded "DataProfilePubSubMessage" (in AutoDLP mode only)
            // Here we try and parse it directly as an "Operation" object or indirectly via the "DataProfilePubSubMessage" proto
            taggerRequest = parseEvent(requestBody);

            BigQueryService bigQueryService = new BigQueryServiceImpl();

            // determine the Type of DLP FindingsReader based on env
            FindingsReader findingsReader = FindingsReaderFactory.getNewReader(
                    FindingsReaderFactory.findReader(
                            environment.getIsAutoDlpMode(),
                            environment.getPromoteMixedTypes()
                    ),
                    bigQueryService,
                    environment.getProjectId(),
                    environment.getDlpDataset(),
                    environment.getIsAutoDlpMode() ? environment.getDlpTableAuto() : environment.getDlpTableStandard(),
                    environment.getConfigViewDatasetDomainMap(),
                    environment.getConfigViewProjectDomainMap(),
                    environment.getConfigViewInfoTypePolicyTagsMap()
            );

            Tagger tagger = new Tagger(
                    environment.toConfig(),
                    bigQueryService,
                    findingsReader,
                    new GCSPersistentSetImpl(environment.getGcsFlagsBucket()),
                    "tagger-flags"
            );

            tagger.execute(
                    taggerRequest,
                    requestBody.getMessage().getMessageId()
            );

            return new ResponseEntity("Process completed successfully.", HttpStatus.OK);
        } catch (Exception e) {

            String trackingId = taggerRequest == null ? defaultTrackingId : taggerRequest.getTrackingId();
            return ControllerExceptionHelper.handleException(e, logger, trackingId);
        }
    }

    private Operation parseEvent(PubSubEvent event) throws NonRetryableApplicationException {

        String defaultTrackingId = "0000000000000-z";

        // check if the message is sent from a Standard DLP inspection job
        if (event.getMessage().getAttributes() != null) {
            String dlpJobName = event.getMessage().getAttributes().getOrDefault("DlpJobName", "");
            if (!dlpJobName.isBlank()) {

                logger.logInfoWithTracker(defaultTrackingId, String.format(
                        "Parsed DlpJobName '%s'",
                        dlpJobName
                ));

                String trackingId = TrackingHelper.extractTrackingIdFromJobName(dlpJobName);
                String runId = TrackingHelper.parseRunIdAsPrefix(trackingId);

                Operation taggerRequest = new Operation(
                        dlpJobName,
                        runId,
                        trackingId
                );

                logger.logInfoWithTracker(taggerRequest.getTrackingId(),
                        String.format("Parsed Request from Standard DLP: %s", taggerRequest.toString()));

                return taggerRequest;
            }
        }

        // try to parse the request as a JSON string if it comes from the dispatcher
        // if not, try to parse it as a proto if it comes from Auto DLP

        try {
            String requestJsonString = event.getMessage().dataToUtf8String();

            // remove any escape characters (e.g. from Terraform
            requestJsonString = requestJsonString.replace("\\", "");

            logger.logInfoWithTracker(defaultTrackingId, String.format("Received payload: %s", requestJsonString));

            Operation taggerRequest = gson.fromJson(requestJsonString, Operation.class);

            logger.logInfoWithTracker(taggerRequest.getTrackingId(),
                    String.format("Parsed Request from Dispatcher: %s", taggerRequest.toString()));

            return taggerRequest;

        } catch (Exception ex) {

            try {
                byte[] data = event.getMessage().getData();

                DataProfilePubSubMessage dataProfilePubSubMessage = DataProfilePubSubMessage.parseFrom(data);

                logger.logInfoWithTracker(defaultTrackingId, String.format(
                        "Parsed DataProfilePubSubMessage= '%s'",
                        dataProfilePubSubMessage
                ));

                TableSpec targetTable = TableSpec.fromFullResource(dataProfilePubSubMessage.getProfile().getFullResource());
                String runId = TrackingHelper.generateOneTimeTaggingSuffix();
                String trackingId = TrackingHelper.generateTrackingId(runId, targetTable.toSqlString());

                Operation taggerRequest = new Operation(
                        targetTable.toSqlString(),
                        runId,
                        trackingId
                );

                logger.logInfoWithTracker(taggerRequest.getTrackingId(),
                        String.format("Parsed Request from Auto DLP notifications : %s", taggerRequest.toString()));

                return taggerRequest;

            } catch (InvalidProtocolBufferException invalidProtocolBufferException) {

                throw new NonRetryableApplicationException(
                        String.format("Couldn't parse PubSub event as Proto: %s : %s",
                                invalidProtocolBufferException.getClass().getSimpleName(),
                                invalidProtocolBufferException.getMessage()
                        ));
            }
        }
    }

    public static void main(String[] args) {
        SpringApplication.run(TaggerController.class, args);
    }
}
