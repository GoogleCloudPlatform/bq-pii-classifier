package com.google.cloud.pso.bq_pii_classifier.services.findings;

import com.google.cloud.dlp.v2.DlpServiceClient;
import com.google.cloud.pso.bq_pii_classifier.entities.DlpFieldFindings;
import com.google.cloud.pso.bq_pii_classifier.entities.*;
import com.google.cloud.pso.bq_pii_classifier.helpers.Utils;
import com.google.privacy.dlp.v2.ColumnDataProfile;
import com.google.privacy.dlp.v2.FileStoreDataProfile;
import com.google.privacy.dlp.v2.ListColumnDataProfilesRequest;

import java.io.IOException;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

public class DlpFindingsReaderImpl implements DlpFindingsReader {

    @Override
    public GcsDlpProfileSummary getGcsDlpProfileSummary(String fileStoreDataProfileName)
            throws IOException, NonRetryableApplicationException {

        try (DlpServiceClient dlpServiceClient = DlpServiceClient.create()) {

            FileStoreDataProfile dataProfile =
                    dlpServiceClient.getFileStoreDataProfile(fileStoreDataProfileName);

            if (dataProfile.getFileStoreIsEmpty()) {
                throw new NonRetryableApplicationException(
                        String.format("No file store data profile found for '%s'", fileStoreDataProfileName));
            }

            return GcsDlpProfileSummary.fromDlpFileStoreDataProfile(dataProfile);
        }
    }

    @Override
    public Map<String, DlpFieldFindings> getBigQueryDlpProfileSummary(String tableProfileName)
            throws IOException {

        Map<String, DlpFieldFindings> fieldsFindings = new HashMap<>();

        try (DlpServiceClient dlpServiceClient = DlpServiceClient.create()) {

            String dlpParent = Utils.extractDlpParentFromProfile(tableProfileName);

            ListColumnDataProfilesRequest request =
                    ListColumnDataProfilesRequest.newBuilder()
                            .setParent(dlpParent)
                            .setFilter(String.format("table_data_profile_name = %s", tableProfileName))
                            .build();

            DlpServiceClient.ListColumnDataProfilesPagedResponse response = dlpServiceClient
                    .listColumnDataProfiles(request);

            Iterable<ColumnDataProfile> columnProfiles = response.iterateAll();

            for (ColumnDataProfile p : columnProfiles) {
                String infoType = p.getColumnInfoType().getInfoType().getName();
                List<DlpOtherInfoTypeMatch> otherInfoTypes =
                        p.getOtherMatchesList().stream()
                                .map(x -> new DlpOtherInfoTypeMatch(x.getInfoType().getName(), x.getEstimatedPrevalence()))
                                .toList();

                fieldsFindings.put(p.getColumn(), new DlpFieldFindings(infoType, otherInfoTypes));
            }
        }

        return fieldsFindings;
    }
}
