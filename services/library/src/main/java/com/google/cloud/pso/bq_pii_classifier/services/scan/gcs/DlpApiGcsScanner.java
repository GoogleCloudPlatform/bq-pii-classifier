package com.google.cloud.pso.bq_pii_classifier.services.scan.gcs;

import com.google.cloud.dlp.v2.DlpServiceClient;
import com.google.cloud.pso.bq_pii_classifier.entities.GcsDlpProfileSummary;
import com.google.cloud.pso.bq_pii_classifier.helpers.Utils;
import com.google.privacy.dlp.v2.FileStoreDataProfile;

import java.io.IOException;
import java.util.*;
import java.util.stream.Collectors;

public class DlpApiGcsScanner implements GcsScanner {

  @Override
  public List<GcsDlpProfileSummary> getGcsDlpProfiles(String orgOrProjectResourceName, String location) throws IOException {

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
}
