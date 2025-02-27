package com.google.cloud.pso.bq_pii_classifier.services.scan.gcs;

import com.google.cloud.bigquery.Job;
import com.google.cloud.bigquery.TableResult;
import com.google.cloud.dlp.v2.DlpServiceClient;
import com.google.cloud.pso.bq_pii_classifier.entities.GcsDlpProfileSummary;
import com.google.cloud.pso.bq_pii_classifier.helpers.Utils;
import com.google.cloud.pso.bq_pii_classifier.services.bq.BigQueryService;
import com.google.common.io.Resources;
import com.google.privacy.dlp.v2.FileStoreDataProfile;

import java.io.IOException;
import java.nio.charset.StandardCharsets;
import java.util.*;
import java.util.stream.Collectors;

public class DlpResultsForGcsScannerImpl implements DlpResultsForGcsScanner {

  private final BigQueryService bqService;
  private final String bqQueryFile;

  public DlpResultsForGcsScannerImpl(BigQueryService bqService, String bqQueryFile) {
    this.bqService = bqService;
    this.bqQueryFile = bqQueryFile;
  }

  @Override
  public List<GcsDlpProfileSummary> getGcsDlpProfilesFromDlpApi(String orgOrProjectResourceName, String location) throws IOException {

      String parent = String.format("%s/locations/%s",
              Utils.stripLeadingAndTrailingSlashes(orgOrProjectResourceName),
              location.strip().equalsIgnoreCase("eu")? "europe": location.strip()
              );

    List<GcsDlpProfileSummary> profileSummaries = new ArrayList<>();

    try (DlpServiceClient dlpServiceClient = DlpServiceClient.create()) {

      DlpServiceClient.ListFileStoreDataProfilesPagedResponse pagedResponseList =
          dlpServiceClient.listFileStoreDataProfiles(parent);

      for (FileStoreDataProfile profile : pagedResponseList.iterateAll()) {

        profileSummaries.add(
            new GcsDlpProfileSummary(
                profile.getName(),
                profile.getFileStorePath(),
                profile.getProjectId(),
                profile.getFileStoreInfoTypeSummariesList().stream()
                    .map(x -> x.getInfoType().getName())
                    .collect(Collectors.toSet())));
      }
    }
    return profileSummaries;
  }

  @Override
  public TableResult getGcsDlpProfilesFromBigQuery(
      String projectName,
      String datasetName,
      String dlpFindingsTable,
      String dispatcherRunsTable,
      String bucketNameRegex,
      String projectNameRegex,
      String runId
      )
      throws IOException, InterruptedException {

    String query = Resources.toString(Resources.getResource(bqQueryFile),
                    StandardCharsets.UTF_8)
            .replace("${project}", projectName)
            .replace("${dataset}", datasetName)
            .replace("${dlp_gcs_results_table}", dlpFindingsTable)
            .replace("${dispatcher_runs_table}", dispatcherRunsTable)
            .replace("${project_name_regex}", projectNameRegex)
            .replace("${bucket_name_regex}", bucketNameRegex)
            .replace("${run_id}", runId)
            ;

    Job dlpFindingsJob = bqService.submitJob(query);
    return bqService.waitAndGetJobResults(dlpFindingsJob);
  }
}
