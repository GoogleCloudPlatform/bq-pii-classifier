/*
 *
 *  Copyright 2025 Google LLC
 *
 *  Licensed under the Apache License, Version 2.0 (the "License");
 *  you may not use this file except in compliance with the License.
 *  You may obtain a copy of the License at
 *
 *       https://www.apache.org/licenses/LICENSE-2.0
 *
 *  Unless required by applicable law or agreed to in writing, software
 *  distributed under the License is distributed on an "AS IS" BASIS,
 *  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or
 *  implied.
 *  See the License for the specific language governing permissions and
 *  limitations under the License.
 *
 */

package com.google.cloud.oss.solutions.annotations.apps.dispatcher;

import com.google.cloud.oss.solutions.annotations.entities.NonRetryableApplicationException;
import com.google.cloud.oss.solutions.annotations.functions.dispatcher.Dispatcher;
import com.google.cloud.oss.solutions.annotations.helpers.LoggingHelper;
import com.google.cloud.oss.solutions.annotations.services.bq.BigQueryServiceImpl;
import com.google.cloud.oss.solutions.annotations.services.pubsub.BigQueryToPubSubStreamer;
import com.google.cloud.oss.solutions.annotations.services.scan.DlpFindingsScanner;
import com.google.cloud.oss.solutions.annotations.services.scan.UniversalDlpFindingsScannerImpl;
import java.io.IOException;
import java.util.Arrays;
import java.util.Map;
import java.util.concurrent.ExecutionException;

/** Base class for all dispatchers. */
public abstract class BaseDispatcher {

  private static final Integer functionNumber = 1;
  protected final Environment environment;
  protected final String runId;

  protected BaseDispatcher(Environment environment) {
    this.runId = getRunId();
    this.environment = environment;
  }

  protected abstract Integer getExpectedArgumentsCount();

  protected abstract String getRunId();

  protected abstract String getSqlTemplate();

  protected abstract BigQueryToPubSubStreamer getBigQueryToPubSubStreamer();

  protected abstract Map<String, String> getTemplateParams(String[] args);

  public void run(String[] args)
      throws NonRetryableApplicationException,
          IOException,
          ExecutionException,
          InterruptedException {

    if (args.length != getExpectedArgumentsCount()) {
      throw new NonRetryableApplicationException(
          String.format(
              "%s arguments are expected. Received %s", getExpectedArgumentsCount(), args.length));
    }

    LoggingHelper logger =
        new LoggingHelper(
            this.getClass().getSimpleName(), functionNumber, environment.getProjectId());

    logger.logInfoWithTracker(
        runId, null, String.format("Received arguments %s ", Arrays.toString(args)));

    try {

      Map<String, String> templateParams = getTemplateParams(args);

      DlpFindingsScanner dlpFindingsScanner =
          new UniversalDlpFindingsScannerImpl(
              getSqlTemplate(),
              templateParams,
              new BigQueryServiceImpl(environment.getProjectId()));

      Dispatcher dispatcher =
          new Dispatcher(
              environment.toConfig(), getBigQueryToPubSubStreamer(), dlpFindingsScanner, runId);

      dispatcher.execute();

    } catch (Exception ex) {
      logger.logNonRetryableExceptions(runId, null, ex);
      throw ex;
    }
  }
}
