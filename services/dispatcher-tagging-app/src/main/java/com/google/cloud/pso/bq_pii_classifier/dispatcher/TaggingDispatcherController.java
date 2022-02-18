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
import com.google.cloud.pso.bq_pii_classifier.helpers.ControllerExceptionHelper;
import com.google.cloud.pso.bq_pii_classifier.helpers.LoggingHelper;
import com.google.cloud.pso.bq_pii_classifier.helpers.TrackingHelper;
import com.google.cloud.pso.bq_pii_classifier.services.BigQueryServiceImpl;
import com.google.cloud.pso.bq_pii_classifier.services.DlpResultsScannerImpl;
import com.google.cloud.pso.bq_pii_classifier.services.PubSubServiceImpl;
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

        try {

            if (requestBody == null || requestBody.getMessage() == null) {
                String msg = "Bad Request: invalid message format";
                logger.logSevereWithTracker(runId, msg);
                throw new NonRetryableApplicationException("Request body or message is Null.");
            }

            String requestJsonString = new String(Base64.getDecoder().decode(
                    requestBody.getMessage().getData()
            ));

            // remove any escape characters (e.g. from Terraform
            requestJsonString = requestJsonString.replace("\\", "");

            logger.logInfoWithTracker(runId, String.format("Received payload: %s", requestJsonString));

            BigQueryScope bqScope = gson.fromJson(requestJsonString, BigQueryScope.class);

            logger.logInfoWithTracker(runId, String.format("Parsed JSON input %s ", bqScope.toString()));

            Dispatcher dispatcher = new Dispatcher(
                    environment.toConfig(),
                    new BigQueryServiceImpl(),
                    new PubSubServiceImpl(),
                    new DlpResultsScannerImpl(
                            new BigQueryServiceImpl(),
                            environment.getBqViewFieldsFindings()
                    ),
                    runId
            );

            dispatcher.execute(bqScope);

            return new ResponseEntity("Process completed successfully.", HttpStatus.OK);

        }
        catch (Exception e ){
            return ControllerExceptionHelper.handleException(e, logger, runId);
        }
    }

    public static void main(String[] args) {
        SpringApplication.run(TaggingDispatcherController.class, args);
    }
}

