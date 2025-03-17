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
package com.google.cloud.pso.bq_pii_classifier.apps.gcs_dispatcher;


import com.google.cloud.pso.bq_pii_classifier.entities.NonRetryableApplicationException;
import com.google.cloud.pso.bq_pii_classifier.functions.dispatcher.Dispatcher;
import com.google.cloud.pso.bq_pii_classifier.helpers.LoggingHelper;
import com.google.cloud.pso.bq_pii_classifier.helpers.TrackingHelper;
import com.google.cloud.pso.bq_pii_classifier.services.bq.BigQueryService;
import com.google.cloud.pso.bq_pii_classifier.services.bq.BigQueryServiceImpl;
import com.google.cloud.pso.bq_pii_classifier.services.pubsub.BigQueryToPubSubStreamerForGcsDispatcher;
import com.google.cloud.pso.bq_pii_classifier.services.scan.DlpFindingsScanner;
import com.google.cloud.pso.bq_pii_classifier.services.scan.UniversalDlpFindingsScannerImpl;
import com.google.cloud.pso.bq_pii_classifier.services.set.GCSPersistentSetImpl;
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
import com.google.cloud.pso.bq_pii_classifier.functions.dispatcher.GcsDlpScope;
import java.util.Map;


@SpringBootApplication
@RestController
public class GcsDispatcherController {

    private final LoggingHelper logger;

    private static final Integer functionNumber = 1;

    private final Gson gson;
    private final Environment environment;

    public GcsDispatcherController() {

        gson = new Gson();
        environment = new Environment();
        logger = new LoggingHelper(
                GcsDispatcherController.class.getSimpleName(),
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
                logger.logSevereWithTracker(runId, runId, msg);
                throw new NonRetryableApplicationException("Request body or message is Null.");
            }

            String requestJsonString = requestBody.getMessage().dataToUtf8String();

            // remove any escape characters (e.g. from Terraform
            requestJsonString = requestJsonString.replace("\\", "");

            logger.logInfoWithTracker(runId, runId, String.format("Received payload: %s", requestJsonString));

            GcsDlpScope gcsDlpScope = gson.fromJson(requestJsonString, GcsDlpScope.class);

            logger.logInfoWithTracker(runId, runId, String.format("Parsed JSON input %s ", gcsDlpScope.toString()));

            BigQueryService bigQueryService = new BigQueryServiceImpl();

            DlpFindingsScanner dlpFindingsScanner = new UniversalDlpFindingsScannerImpl(
                    "sql/v_gcs_dispatcher.tpl",
                    Map.of(
                            "${project}", environment.getProjectId(),
                            "${dataset}", environment.getDlpResultsDataset(),
                            "${dlp_gcs_results_table}", environment.getDlpResultsTable(),
                            "${dispatcher_runs_table}", environment.getDispatcherRunsTable(),
                            "${project_name_regex}", gcsDlpScope.projectsRegex(),
                            "${bucket_name_regex}", gcsDlpScope.bucketsRegex(),
                            "${run_id}", runId),
                    bigQueryService
            );

            Dispatcher dispatcher =
                    new Dispatcher(
                            environment.toConfig(),
                            new BigQueryToPubSubStreamerForGcsDispatcher(),
                            dlpFindingsScanner,
                            new GCSPersistentSetImpl(environment.getGcsFlagsBucket()),
                            "tagging-dispatcher-gcs-flags",
                            runId);

            dispatcher.execute(requestBody.getMessage().getMessageId());

        } catch (Exception e) {
            logger.logNonRetryableExceptions(runId, runId, e);
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
        SpringApplication.run(GcsDispatcherController.class, args);
    }
}

