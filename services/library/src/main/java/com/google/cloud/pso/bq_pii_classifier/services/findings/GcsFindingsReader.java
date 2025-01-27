package com.google.cloud.pso.bq_pii_classifier.services.findings;

import com.google.cloud.pso.bq_pii_classifier.entities.NonRetryableApplicationException;

import java.io.IOException;
import java.util.Set;

public interface GcsFindingsReader {

    Set<String> getFileStoreDataProfileDetectedInfoTypes(String fileStoreDataProfileName) throws IOException, NonRetryableApplicationException;

}
