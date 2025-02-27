package com.google.cloud.pso.bq_pii_classifier.services.scan.gcs;

import com.google.cloud.bigquery.TableResult;
import com.google.cloud.pso.bq_pii_classifier.entities.GcsDlpProfileSummary;

import java.io.IOException;
import java.util.List;

public interface DlpResultsForGcsScanner {

    /**
     *
     * @param orgOrProjectResourceName Resource name of the organization or project, for example organizations/433245324 or projects/project-id.
     * @param location GCP region where buckets are located. Only profiles of buckets in that given region will be listed
     * @return a list of GcsDlpProfileSummary
     */
    List<GcsDlpProfileSummary> getGcsDlpProfilesFromDlpApi(String orgOrProjectResourceName, String location) throws IOException;

  TableResult getGcsDlpProfilesFromBigQuery(
      String projectName,
      String datasetName,
      String dlpFindingsTable,
      String dispatcherRunsTable,
      String bucketNameRegex,
      String projectNameRegex,
      String runId
      )
      throws IOException, InterruptedException;
}
