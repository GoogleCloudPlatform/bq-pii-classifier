package com.google.cloud.pso.bq_pii_classifier.services.findings;

import com.google.cloud.pso.bq_pii_classifier.entities.GcsDlpProfileSummary;
import com.google.cloud.pso.bq_pii_classifier.entities.NonRetryableApplicationException;
import com.google.cloud.pso.bq_pii_classifier.entities.TableColumnsInfoTypes;

import java.io.IOException;

public interface DlpFindingsReader {

    GcsDlpProfileSummary getGcsDlpProfileSummary(String fileStoreDataProfileName) throws IOException, NonRetryableApplicationException;

    TableColumnsInfoTypes getBigQueryDlpProfileSummary(String dlpParent, String tableProfileName, boolean promoteDlpOtherMatches) throws IOException;

}
