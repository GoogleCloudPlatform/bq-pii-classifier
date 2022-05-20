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
package com.google.cloud.pso.bq_pii_classifier.dispatcher;


import com.google.cloud.pso.bq_pii_classifier.functions.dispatcher.BigQueryScope;
import com.google.cloud.pso.bq_pii_classifier.functions.dispatcher.Dispatcher;
import com.google.cloud.pso.bq_pii_classifier.entities.NonRetryableApplicationException;
import com.google.cloud.pso.bq_pii_classifier.helpers.LoggingHelper;
import com.google.cloud.pso.bq_pii_classifier.helpers.TrackingHelper;
import com.google.cloud.pso.bq_pii_classifier.services.bq.BigQueryServiceImpl;
import com.google.cloud.pso.bq_pii_classifier.services.pubsub.PubSubPublishResults;
import com.google.cloud.pso.bq_pii_classifier.services.pubsub.PubSubServiceImpl;
import com.google.cloud.pso.bq_pii_classifier.services.set.GCSPersistentSetImpl;
import com.google.cloud.pso.bq_pii_classifier.services.scan.*;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestMethod;
import com.google.gson.Gson;
import com.google.cloud.pso.bq_pii_classifier.entities.PubSubEvent;

import java.util.Base64;


@SpringBootApplication(scanBasePackages = "com.google.cloud.pso.bq_pii_classifier")
@RestController
public class TaggingDispatcherController {

    private final LoggingHelper logger;

    private static final Integer functionNumber = 1;

    private Gson gson;
    private Environment environment;

    public TaggingDispatcherController() {

        gson = new Gson();
        environment = new Environment();
        logger = new LoggingHelper(
                TaggingDispatcherController.class.getSimpleName(),
                functionNumber,
                environment.getProjectId());
    }

    @RequestMapping(value = "/", method = RequestMethod.POST)
    public ResponseEntity receiveMessage(@RequestBody PubSubEvent requestBody) {

        String runId = TrackingHelper.generateTaggingRunId();
        String state = "";

        try {

            if (requestBody == null || requestBody.getMessage() == null) {
                String msg = "Bad Request: invalid message format";
                logger.logSevereWithTracker(runId, msg);
                throw new NonRetryableApplicationException("Request body or message is Null.");
            }

            String requestJsonString = requestBody.getMessage().dataToUtf8String();

            // remove any escape characters (e.g. from Terraform
            requestJsonString = requestJsonString.replace("\\", "");

            logger.logInfoWithTracker(runId, String.format("Received payload: %s", requestJsonString));

            BigQueryScope bqScope = gson.fromJson(requestJsonString, BigQueryScope.class);

            logger.logInfoWithTracker(runId, String.format("Parsed JSON input %s ", bqScope.toString()));

            Scanner dlpResultsScanner;
            if (environment.getIsAutoDlpMode()){
                dlpResultsScanner = new AutoDlpResultsScannerImpl(
                        environment.getProjectId(),
                        environment.getSolutionDataset(),
                        environment.getDlpTableAuto(),
                        new BigQueryServiceImpl()
                );
            }else{
                dlpResultsScanner = new StandardDlpResultsScannerImpl(
                        environment.getProjectId(),
                        environment.getSolutionDataset(),
                        environment.getDlpTableStandard(),
                        environment.getLoggingTable(),
                        new BigQueryServiceImpl()
                );
            }

            Dispatcher dispatcher = new Dispatcher(
                    environment.toConfig(),
                    new BigQueryServiceImpl(),
                    new PubSubServiceImpl(),
                    dlpResultsScanner,
                    new GCSPersistentSetImpl(environment.getGcsFlagsBucket()),
                    "tagging-dispatcher-flags",
                    runId
            );

            PubSubPublishResults results = dispatcher.execute(bqScope, requestBody.getMessage().getMessageId());

            state = String.format("Publishing results: %s SUCCESS MESSAGES and %s FAILED MESSAGES",
                    results.getSuccessMessages().size(),
                    results.getFailedMessages().size());

            logger.logInfoWithTracker(runId, state);

        } catch (Exception e) {
            logger.logNonRetryableExceptions(runId, e);
            state = String.format("ERROR '%s'", e.getMessage());
        }

        // Always ACK the pubsub message to avoid retries
        // The dispatcher is the entry point and retrying it could cause
        // unnecessary runs and costs

        return new ResponseEntity(
                String.format("Process completed with state = %s", state),
                HttpStatus.OK);
    }

    public static void main(String[] args) {
        SpringApplication.run(TaggingDispatcherController.class, args);
    }
}

