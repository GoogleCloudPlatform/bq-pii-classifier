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
package com.google.cloud.pso.bq_pii_classifier.listener;

import com.google.api.gax.rpc.ApiException;
import com.google.cloud.pso.bq_pii_classifier.entities.TableOperationRequest;
import com.google.cloud.pso.bq_pii_classifier.functions.listener.Listener;
import com.google.cloud.pso.bq_pii_classifier.functions.listener.ListenerConfig;
import com.google.cloud.pso.bq_pii_classifier.helpers.ControllerExceptionHelper;
import com.google.cloud.pso.bq_pii_classifier.helpers.LoggingHelper;
import com.google.cloud.pso.bq_pii_classifier.entities.NonRetryableApplicationException;
import com.google.cloud.pso.bq_pii_classifier.entities.PubSubEvent;
import com.google.cloud.pso.bq_pii_classifier.helpers.TrackingHelper;
import com.google.cloud.pso.bq_pii_classifier.helpers.Utils;
import com.google.cloud.pso.bq_pii_classifier.services.DlpService;
import com.google.cloud.pso.bq_pii_classifier.services.DlpServiceImpl;
import com.google.cloud.pso.bq_pii_classifier.services.PubSubService;
import com.google.cloud.pso.bq_pii_classifier.services.PubSubServiceImpl;
import com.google.common.collect.Sets;
import com.google.gson.Gson;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestMethod;

import java.io.IOException;
import java.util.Base64;
import java.util.Map;
import java.util.Set;

import com.google.cloud.pso.bq_pii_classifier.functions.tagger.Tagger;

@SpringBootApplication(scanBasePackages = "com.google.cloud.pso.bq_pii_classifier")
@RestController
public class ListenerController {

    private final LoggingHelper logger;


    private static final Integer functionNumber = 3;

    private Gson gson;
    Environment environment;

    public ListenerController() {

        gson = new Gson();
        environment = new Environment();
        logger = new LoggingHelper(
                ListenerController.class.getSimpleName(),
                functionNumber,
                environment.getProjectId()
        );
    }

    @RequestMapping(value = "/", method = RequestMethod.POST)
    public ResponseEntity receiveMessage(@RequestBody PubSubEvent requestBody) {

        String trackingId = "NA";
        DlpService dlpService = null;
        PubSubService pubSubService = null;

        try {

            if (requestBody == null || requestBody.getMessage() == null) {
                String msg = "Bad Request: invalid message format";
                logger.logSevereWithTracker("NA", msg);
                throw new NonRetryableApplicationException("Request body or message is Null.");
            }

            String dlpJobName = requestBody.getMessage().getAttributes().getOrDefault("DlpJobName", "");


            if (dlpJobName.isBlank()) {
                throw new NonRetryableApplicationException("DlpJobName message attribute is missing");
            }

            // dlp job is created using the trackingId via the Inspector CF
            trackingId = TrackingHelper.extractTrackingIdFromJobName(dlpJobName);

            logger.logInfoWithTracker(trackingId, String.format("Received jobName: %s", dlpJobName));
            logger.logInfoWithTracker(trackingId, String.format("Parsed trackingId: %s", trackingId));

            dlpService = new DlpServiceImpl();
            pubSubService = new PubSubServiceImpl();
            Listener listener = new Listener(
                    environment.toConfig(),
                    dlpService,
                    pubSubService
            );

            listener.execute(dlpJobName, trackingId);

            return new ResponseEntity("Process completed successfully.", HttpStatus.OK);

        } catch (Exception e) {
            return ControllerExceptionHelper.handleException(e, logger, trackingId);
        } finally {

            if (dlpService != null) {
                dlpService.shutDown();
            }
        }
    }

    public static void main(String[] args) {
        SpringApplication.run(ListenerController.class, args);
    }
}
