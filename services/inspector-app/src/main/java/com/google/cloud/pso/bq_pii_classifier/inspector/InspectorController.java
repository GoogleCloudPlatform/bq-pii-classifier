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
package com.google.cloud.pso.bq_pii_classifier.inspector;

import com.google.api.gax.rpc.ApiException;
import com.google.api.gax.rpc.ResourceExhaustedException;
import com.google.cloud.pso.bq_pii_classifier.entities.TableOperationRequest;
import com.google.cloud.pso.bq_pii_classifier.functions.inspector.Inspector;
import com.google.cloud.pso.bq_pii_classifier.helpers.ControllerExceptionHelper;
import com.google.cloud.pso.bq_pii_classifier.helpers.LoggingHelper;
import com.google.cloud.pso.bq_pii_classifier.entities.NonRetryableApplicationException;
import com.google.cloud.pso.bq_pii_classifier.entities.PubSubEvent;
import com.google.cloud.pso.bq_pii_classifier.services.BigQueryService;
import com.google.cloud.pso.bq_pii_classifier.services.BigQueryServiceImpl;
import com.google.cloud.pso.bq_pii_classifier.services.DlpService;
import com.google.cloud.pso.bq_pii_classifier.services.DlpServiceImpl;
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

import com.google.cloud.pso.bq_pii_classifier.functions.tagger.Tagger;

import javax.net.ssl.SSLException;

@SpringBootApplication(scanBasePackages = "com.google.cloud.pso.bq_pii_classifier")
@RestController
public class InspectorController {

    private final LoggingHelper logger;

    private static final Integer functionNumber = 4;

    private Gson gson;
    Environment environment;

    public InspectorController() {

        gson = new Gson();
        environment = new Environment();
        logger = new LoggingHelper(
                InspectorController.class.getSimpleName(),
                functionNumber,
                environment.getProjectId()
                );
    }

    @RequestMapping(value = "/", method = RequestMethod.POST)
    public ResponseEntity receiveMessage(@RequestBody PubSubEvent requestBody) {

        String trackingId = "NA";
        DlpService dlpService = null;
        BigQueryService bqService = null;

        try {

            if (requestBody == null || requestBody.getMessage() == null) {
                String msg = "Bad Request: invalid message format";
                logger.logSevereWithTracker("NA", msg);
                throw new NonRetryableApplicationException("Request body or message is Null.");
            }

            String requestJsonString = new String(Base64.getDecoder().decode(
                    requestBody.getMessage().getData()
            ));

            // remove any escape characters (e.g. from Terraform
            requestJsonString = requestJsonString.replace("\\", "");

            logger.logInfoWithTracker(trackingId, String.format("Received payload: %s", requestJsonString));

            TableOperationRequest tableOperationRequest = gson.fromJson(requestJsonString, TableOperationRequest.class);

            trackingId = tableOperationRequest.getTrackingId();

            logger.logInfoWithTracker(trackingId, String.format("Parsed Request: %s", tableOperationRequest.toString()));

            dlpService = new DlpServiceImpl();
            bqService = new BigQueryServiceImpl();
            Inspector inspector = new Inspector(
                    environment.toConfig(),
                    dlpService,
                    bqService
            );

            inspector.execute(tableOperationRequest, trackingId);

            return new ResponseEntity("Process completed successfully.", HttpStatus.OK);

        }
        catch (Exception e ){
            return ControllerExceptionHelper.handleException(e, logger, trackingId);

        }finally {

            if (dlpService != null){
                dlpService.shutDown();
            }
        }
    }

    public static void main(String[] args) {
        SpringApplication.run(InspectorController.class, args);
    }
}
