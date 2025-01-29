package com.google.cloud.pso.bq_pii_classifier.services.findings.gcs;

import com.google.cloud.pso.bq_pii_classifier.entities.GcsDlpProfileSummary;
import com.google.cloud.pso.bq_pii_classifier.entities.NonRetryableApplicationException;

import java.io.IOException;
import java.util.Set;

public interface GcsFindingsReader {

    GcsDlpProfileSummary getGcsDlpProfileSummary(String fileStoreDataProfileName) throws IOException, NonRetryableApplicationException;

}
