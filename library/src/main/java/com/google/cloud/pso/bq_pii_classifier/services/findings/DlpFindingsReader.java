package com.google.cloud.pso.bq_pii_classifier.services.findings;

import com.google.cloud.pso.bq_pii_classifier.entities.DlpFieldFindings;
import com.google.cloud.pso.bq_pii_classifier.entities.GcsDlpProfileSummary;
import com.google.cloud.pso.bq_pii_classifier.entities.NonRetryableApplicationException;

import java.io.IOException;
import java.util.Map;

public interface DlpFindingsReader {

    GcsDlpProfileSummary getGcsDlpProfileSummary(String fileStoreDataProfileName) throws IOException, NonRetryableApplicationException;

    Map<String, DlpFieldFindings> getBigQueryDlpProfileSummary(String tableProfileName) throws IOException;

}
