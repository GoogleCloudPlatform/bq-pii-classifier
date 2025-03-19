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
package com.google.cloud.pso.bq_pii_classifier.apps.bq_dispatcher;

import com.google.cloud.pso.bq_pii_classifier.entities.NonRetryableApplicationException;
import com.google.cloud.pso.bq_pii_classifier.functions.dispatcher.BigQueryDlpScope;
import com.google.cloud.pso.bq_pii_classifier.functions.dispatcher.Dispatcher;
import com.google.cloud.pso.bq_pii_classifier.helpers.LoggingHelper;
import com.google.cloud.pso.bq_pii_classifier.helpers.TrackingHelper;
import com.google.cloud.pso.bq_pii_classifier.services.bq.BigQueryService;
import com.google.cloud.pso.bq_pii_classifier.services.bq.BigQueryServiceImpl;
import com.google.cloud.pso.bq_pii_classifier.services.pubsub.BigQueryToPubSubStreamerForBQDispatcher;
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

import java.util.HashMap;
import java.util.Map;

@SpringBootApplication
@RestController
public class BigQueryDispatcherController {

  private final LoggingHelper logger;

  private static final Integer functionNumber = 1;

  private final Gson gson;
  private final Environment environment;

  public BigQueryDispatcherController() {

    gson = new Gson();
    environment = new Environment();
    logger =
        new LoggingHelper(
            BigQueryDispatcherController.class.getSimpleName(),
            functionNumber,
            environment.getProjectId());
  }

  @RequestMapping(value = "/", method = RequestMethod.POST)
  public ResponseEntity receiveMessage(@RequestBody PubSubEvent requestBody) {

    String runId = TrackingHelper.generateTaggingRunIdForBigQuery();
    String state = "";

    try {

      if (requestBody == null || requestBody.getMessage() == null) {
        String msg = "Bad Request: invalid message format";
        logger.logSevereWithTracker(runId, null, msg);
        throw new NonRetryableApplicationException("Request body or message is Null.");
      }

      String requestJsonString = requestBody.getMessage().dataToUtf8String();

      // remove any escape characters (e.g. from Terraform
      requestJsonString = requestJsonString.replace("\\", "");

      logger.logInfoWithTracker(runId, null, String.format("Received payload: %s", requestJsonString));

      BigQueryDlpScope bigQueryDlpScope = gson.fromJson(requestJsonString, BigQueryDlpScope.class);

      logger.logInfoWithTracker(
          runId, null, String.format("Parsed JSON input %s ", bigQueryDlpScope.toString()));

      BigQueryService bigQueryService = new BigQueryServiceImpl();

      Map<String, String> sqlParamsMap = new HashMap<>();
      sqlParamsMap.put("${project}", environment.getProjectId());
      sqlParamsMap.put("${dataset}", environment.getSolutionDataset());
      sqlParamsMap.put("${results_table}", environment.getDlpTableAuto());
      sqlParamsMap.put("${project_id_regex}", bigQueryDlpScope.projectsRegex());
      sqlParamsMap.put("${dataset_id_regex}", bigQueryDlpScope.datasetsRegex());
      sqlParamsMap.put("${table_id_regex}", bigQueryDlpScope.tablesRegex());
      sqlParamsMap.put("${dispatcher_runs_table}", environment.getDispatcherRunsTable());
      sqlParamsMap.put("${run_id}", runId);

      logger.logInfoWithTracker(runId, null, String.format("Sql parameters map %s", sqlParamsMap));

      DlpFindingsScanner dlpFindingsScanner =
          new UniversalDlpFindingsScannerImpl(
              "sql/v_bq_auto_dlp_dispatcher.tpl", sqlParamsMap, bigQueryService);

      Dispatcher dispatcher =
          new Dispatcher(
              environment.toConfig(),
              new BigQueryToPubSubStreamerForBQDispatcher(),
              dlpFindingsScanner,
              new GCSPersistentSetImpl(environment.getGcsFlagsBucket()),
              "tagging-dispatcher-flags",
              runId);

      dispatcher.execute(requestBody.getMessage().getMessageId());

    } catch (Exception e) {
      logger.logNonRetryableExceptions(runId, null, e);
      state = String.format("ERROR '%s'", e.getMessage());
    }

    // Always ACK the pubsub message to avoid retries
    // The dispatcher is the entry point and retrying it could cause
    // unnecessary runs and costs
    return new ResponseEntity(
        String.format("Process completed with state = %s", state), HttpStatus.OK);
  }

  public static void main(String[] args) {
    SpringApplication.run(BigQueryDispatcherController.class, args);
  }
}
