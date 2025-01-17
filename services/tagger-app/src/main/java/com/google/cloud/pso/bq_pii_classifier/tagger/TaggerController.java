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
import com.google.cloud.pso.bq_pii_classifier.functions.tagger.TaggerDlpJobRequest;
import com.google.cloud.pso.bq_pii_classifier.functions.tagger.TaggerTableSpecRequest;
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


            if (taggerRequest instanceof TaggerTableSpecRequest) {
                TaggerTableSpecRequest taggerTableSpecRequest = (TaggerTableSpecRequest) taggerRequest;
                tagger.execute(taggerTableSpecRequest, requestBody.getMessage().getMessageId());
            } else {
                if (taggerRequest instanceof TaggerDlpJobRequest) {
                    TaggerDlpJobRequest taggerDlpJobRequest = (TaggerDlpJobRequest) taggerRequest;
                    tagger.execute(taggerDlpJobRequest, requestBody.getMessage().getMessageId());
                }
            }

            return new ResponseEntity("Process completed successfully.", HttpStatus.OK);
        } catch (Exception e) {

            String trackingId = taggerRequest == null ? defaultTrackingId : taggerRequest.getTrackingId();
            return ControllerExceptionHelper.handleException(e, logger, trackingId);
        }
    }

    // The pubsub message could come from different sources with different formats
    // 1. From DLP job notification in Standard Mode as a JSON message with the DLPJobName --> should be parsed as TaggerDlpJobRequest
    // 2. From Tagging Dispatcher Service in Standard Mode as TaggerDlpJobRequest
    // 3. From Tagging Dispatcher Service in AutoDlp Mode as TaggerTableSpecRequest
    // 4. From Auto DLP job notification in AutoDlp Mode as "DataProfilePubSubMessage" proto --> should be parsed as TaggerTableSpecRequest


    private Operation parseEvent(PubSubEvent event) throws NonRetryableApplicationException {

        String defaultTrackingId = "0000000000000-z";

        // check if the message is sent from a Standard DLP inspection job, if so map it to TaggerDlpJobRequest
        logger.logInfoWithTracker(defaultTrackingId,"Attempt: Will try to parse request as TaggerDlpJobRequest from Standard DLP Mode..");

        if (event.getMessage().getAttributes() != null) {
            String dlpJobName = event.getMessage().getAttributes().getOrDefault("DlpJobName", "");
            if (!dlpJobName.isBlank()) {

                logger.logInfoWithTracker(defaultTrackingId, String.format(
                        "Parsed DlpJobName '%s'",
                        dlpJobName
                ));

                String trackingId = TrackingHelper.extractTrackingIdFromJobName(dlpJobName);
                String runId = TrackingHelper.parseRunIdAsPrefix(trackingId);

                TaggerDlpJobRequest taggerDlpJobRequest = new TaggerDlpJobRequest(
                        runId,
                        trackingId,
                        dlpJobName
                );

                logger.logInfoWithTracker(taggerDlpJobRequest.getTrackingId(),
                        String.format("Final: Parsed Request from Standard DLP: %s", taggerDlpJobRequest.toString()));

                // CASE 1: TaggerDlpJobRequest in Standard Mode from a DLP PubSub notification
                return taggerDlpJobRequest;
            }
        }

        try {
            String requestJsonString = event.getMessage().dataToUtf8String();

            // remove any escape characters (e.g. from Terraform
            requestJsonString = requestJsonString.replace("\\", "");

            logger.logInfoWithTracker(defaultTrackingId, String.format("Received payload: %s", requestJsonString));

            TaggerDlpJobRequest taggerDlpJobRequest = gson.fromJson(requestJsonString, TaggerDlpJobRequest.class);

            if (taggerDlpJobRequest.getDlpJobName() != null && !taggerDlpJobRequest.getDlpJobName().isEmpty()) {

                logger.logInfoWithTracker(taggerDlpJobRequest.getTrackingId(),
                        String.format("Final: parsed Request from Tagging Dispatcher in Standard Mode: %s", taggerDlpJobRequest));

                // CASE 2: TaggerDlpJobRequest from the Tagging Dispatcher Service in Standard Mode
                return taggerDlpJobRequest;
            } else {

                TaggerTableSpecRequest taggerTableRequest = gson.fromJson(requestJsonString, TaggerTableSpecRequest.class);

                if (taggerTableRequest.getTargetTable() == null) {
                    throw new NonRetryableApplicationException("Failed to parse Tagger request as a valid TaggerDlpJobRequest or TaggerTableSpecRequest");
                }

                logger.logInfoWithTracker(taggerTableRequest.getTrackingId(),
                        String.format("Final: Parsed Request from Tagging Dispatcher in Auto DLP Mode: %s", taggerTableRequest));

                // CASE 3: TaggerTableSpecRequest from the Tagging Dispatcher Service in Auto-DLP Mode
                return taggerTableRequest;
            }

        } catch (Exception ex) {

            // if not, try to parse it as a proto if it comes from Auto DLP and map it to TaggerTableSpecRequest
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

                TaggerTableSpecRequest taggerTableSpecRequestFromAutoDlp = new TaggerTableSpecRequest(
                        runId,
                        trackingId,
                        targetTable
                );

                logger.logInfoWithTracker(taggerTableSpecRequestFromAutoDlp.getTrackingId(),
                        String.format("Parsed Request from Auto DLP notifications : %s", taggerTableSpecRequestFromAutoDlp.toString()));

                // CASE 4: TaggerTableSpecRequest from Auto DLP Notification
                return taggerTableSpecRequestFromAutoDlp;

            } catch (Exception ex2) {

                throw new NonRetryableApplicationException(
                        String.format("Couldn't parse PubSub event as Proto: %s : %s",
                                ex2.getClass().getSimpleName(),
                                ex2.getMessage()
                        ));
            }
        }
    }

    public static void main(String[] args) {
        SpringApplication.run(TaggerController.class, args);
    }
}
