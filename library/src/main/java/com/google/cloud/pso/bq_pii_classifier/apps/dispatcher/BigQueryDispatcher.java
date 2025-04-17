package com.google.cloud.pso.bq_pii_classifier.apps.dispatcher;


import com.google.cloud.pso.bq_pii_classifier.entities.NonRetryableApplicationException;
import com.google.cloud.pso.bq_pii_classifier.helpers.TrackingHelper;
import com.google.cloud.pso.bq_pii_classifier.services.pubsub.BigQueryToPubSubStreamer;
import com.google.cloud.pso.bq_pii_classifier.services.pubsub.BigQueryToPubSubStreamerForBQDispatcher;
import java.io.IOException;
import java.util.Map;
import java.util.concurrent.ExecutionException;

public class BigQueryDispatcher extends BaseDispatcher {

    public BigQueryDispatcher(Environment environment) {
        super(environment);
    }

    @Override
    protected Integer getExpectedArgumentsCount() {
        return 4;
    }

    @Override
    protected String getRunId() {
        return TrackingHelper.generateTaggingRunIdForBigQuery();
    }

    @Override
    protected String getSqlTemplate() {
        return "sql/dispatcher_bq.tpl";
    }

    @Override
    protected BigQueryToPubSubStreamer getBigQueryToPubSubStreamer() {
        return new BigQueryToPubSubStreamerForBQDispatcher();
    }

    @Override
    protected Map<String, String> getTemplateParams(String[] args) {

        String foldersRegex = args[0];
        String projectsRegex = args[1];
        String datasetsRegex = args[2];
        String tablesRegex = args[3];

        return Map.of(
                "${project}", this.environment.getPublishingProjectId(),
                "${dataset}", this.environment.getDlpResultsDataset(),
                "${results_table}", this.environment.getDlpResultsTable(),
                "${folder_id_regex}", foldersRegex,
                "${project_id_regex}", projectsRegex,
                "${dataset_id_regex}", datasetsRegex,
                "${table_id_regex}", tablesRegex,
                "${dispatcher_runs_table}", this.environment.getDispatcherRunsTable(),
                "${run_id}", this.runId
        );
    }

    public static void main(String [] args) throws NonRetryableApplicationException, IOException, ExecutionException, InterruptedException {
        new BigQueryDispatcher(new Environment()).run(args);
    }
}
