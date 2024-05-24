package com.google.cloud.pso.bq_pii_classifier.functions.tagger;

import com.google.cloud.pso.bq_pii_classifier.entities.Operation;

public class TaggerDlpJobRequest extends Operation {

    private String dlpJobName;

    public TaggerDlpJobRequest(String runId, String trackingId, String dlpJobName) {
        super(runId, trackingId);
        this.dlpJobName = dlpJobName;
    }

    public String getDlpJobName() {
        return dlpJobName;
    }

    @Override
    public String toString() {
        return "TaggerDispatcherRequest{" +
                "dlpJobName='" + dlpJobName + '\'' +
                "} " + super.toString();
    }
}
