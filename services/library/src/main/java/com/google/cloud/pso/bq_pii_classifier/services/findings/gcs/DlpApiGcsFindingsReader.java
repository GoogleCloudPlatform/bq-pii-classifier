package com.google.cloud.pso.bq_pii_classifier.services.findings.gcs;

import com.google.cloud.dlp.v2.DlpServiceClient;
import com.google.cloud.pso.bq_pii_classifier.entities.NonRetryableApplicationException;
import com.google.privacy.dlp.v2.FileStoreDataProfile;
import com.google.privacy.dlp.v2.FileStoreInfoTypeSummary;

import java.io.IOException;
import java.util.HashSet;
import java.util.List;
import java.util.Set;
import java.util.stream.Collectors;

public class DlpApiGcsFindingsReader implements GcsFindingsReader {

  @Override
  public Set<String> getFileStoreDataProfileDetectedInfoTypes(String fileStoreDataProfileName)
      throws IOException, NonRetryableApplicationException {

        try (DlpServiceClient dlpServiceClient = DlpServiceClient.create()) {

            FileStoreDataProfile dataProfile = dlpServiceClient.getFileStoreDataProfile(fileStoreDataProfileName);

            if(dataProfile.getFileStoreIsEmpty()){
                throw new NonRetryableApplicationException(
                        String.format("No file store data profile found for '%s'", fileStoreDataProfileName)
                );
            }

            if(dataProfile.getFileStoreInfoTypeSummariesCount() == 0){
                return new HashSet<>(0);
            }

            List<FileStoreInfoTypeSummary> infoTypeSummaryList = dataProfile.getFileStoreInfoTypeSummariesList();
            return infoTypeSummaryList.stream().map(x->x.getInfoType().getName()).collect(Collectors.toSet());
        }
    }
}
