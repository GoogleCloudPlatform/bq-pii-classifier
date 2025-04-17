package com.google.cloud.pso.bq_pii_classifier.apps.dispatcher;

import com.google.cloud.pso.bq_pii_classifier.entities.NonRetryableApplicationException;
import com.google.cloud.pso.bq_pii_classifier.functions.dispatcher.Dispatcher;
import com.google.cloud.pso.bq_pii_classifier.helpers.LoggingHelper;
import com.google.cloud.pso.bq_pii_classifier.services.bq.BigQueryServiceImpl;
import com.google.cloud.pso.bq_pii_classifier.services.pubsub.BigQueryToPubSubStreamer;
import com.google.cloud.pso.bq_pii_classifier.services.scan.DlpFindingsScanner;
import com.google.cloud.pso.bq_pii_classifier.services.scan.UniversalDlpFindingsScannerImpl;

import java.io.IOException;
import java.util.Arrays;
import java.util.Map;
import java.util.concurrent.ExecutionException;
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

    public void run(String [] args) throws NonRetryableApplicationException, IOException, ExecutionException, InterruptedException {

        if (args.length != getExpectedArgumentsCount()){
            throw new NonRetryableApplicationException(String.format("%s arguments are expected. Received %s", getExpectedArgumentsCount(), args.length));
        }

    LoggingHelper logger =
        new LoggingHelper(
            this.getClass().getSimpleName(), functionNumber, environment.getProjectId());

        logger.logInfoWithTracker(
                runId, null, String.format("Received arguments %s ", Arrays.toString(args)));

        try{

            Map<String, String> templateParams = getTemplateParams(args);

      DlpFindingsScanner dlpFindingsScanner =
          new UniversalDlpFindingsScannerImpl(
              getSqlTemplate(),
              templateParams,
              new BigQueryServiceImpl(environment.getProjectId()));

            Dispatcher dispatcher =
                    new Dispatcher(
                            environment.toConfig(),
                            getBigQueryToPubSubStreamer(),
                            dlpFindingsScanner,
                            runId);

            dispatcher.execute();

        }catch (Exception ex){
            logger.logNonRetryableExceptions(runId, null, ex);
            throw ex;
        }
    }
}