package com.google.cloud.pso.bq_pii_classifier.services.findings;

import com.google.cloud.dlp.v2.DlpServiceClient;
import com.google.cloud.pso.bq_pii_classifier.entities.GcsDlpProfileSummary;
import com.google.cloud.pso.bq_pii_classifier.entities.NonRetryableApplicationException;
import com.google.cloud.pso.bq_pii_classifier.entities.TableColumnsInfoTypes;
import com.google.cloud.pso.bq_pii_classifier.entities.TableSpec;
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
    public TableColumnsInfoTypes getBigQueryDlpProfileSummary(String dlpParent, String tableProfileName, boolean promoteDlpOtherMatches)
            throws IOException {

        TableColumnsInfoTypes tableColumnsInfoTypes = null;

        try (DlpServiceClient dlpServiceClient = DlpServiceClient.create()) {

            ListColumnDataProfilesRequest request =
                    ListColumnDataProfilesRequest.newBuilder()
                            .setParent(dlpParent)
                            .setFilter(String.format("table_data_profile_name = %s", tableProfileName))
                            .build();

            Map<String, String> columnsInfoType = new HashMap<>();


            for (ColumnDataProfile p : dlpServiceClient.listColumnDataProfiles(request).iterateAll()) {
                String infoType = p.getColumnInfoType().getInfoType().getName();
                List<String> otherInfoTypes =
                        p.getOtherMatchesList().stream().map(x -> x.getInfoType().getName()).toList();

                String promotedInfoType = computeFinalInfoType(infoType, otherInfoTypes, promoteDlpOtherMatches);

                columnsInfoType.put(p.getColumn(), promotedInfoType);

                tableColumnsInfoTypes = new TableColumnsInfoTypes(TableSpec.fromFullResource(p.getTableFullResource()), columnsInfoType);
            }
        }

        return tableColumnsInfoTypes;
    }

    public static String computeFinalInfoType(String mainDlpInfoType, List<String> otherDlpInfoTypes, boolean promoteDlpOtherMatches){
        if (promoteDlpOtherMatches){
            if (mainDlpInfoType != null && !mainDlpInfoType.isEmpty()) {
                return mainDlpInfoType;
            } else {
                // if dlp doesn't detect a main dlp with high confidence then consider other info types it found
                if (otherDlpInfoTypes != null && otherDlpInfoTypes.size() == 1) {
                    return otherDlpInfoTypes.get(0);
                } else {
                    if (otherDlpInfoTypes != null && otherDlpInfoTypes.size() > 1) {
                        return "MIXED";
                    } else {
                        return null;
                    }
                }
            }
        }else{
            // if no promotion logic is required then just use the main Dlp info type
            return mainDlpInfoType;
        }
    }
}
