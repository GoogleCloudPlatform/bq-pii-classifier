package com.google.cloud.pso.bq_pii_classifier.services.findings;

import com.google.cloud.pso.bq_pii_classifier.entities.NonRetryableApplicationException;
import com.google.cloud.pso.bq_pii_classifier.entities.TablePolicyTags;

import java.io.IOException;

public interface FindingsReader {

    TablePolicyTags getFieldsToPolicyTagsMap(String lookupKey) throws InterruptedException, NonRetryableApplicationException, IOException;

}
