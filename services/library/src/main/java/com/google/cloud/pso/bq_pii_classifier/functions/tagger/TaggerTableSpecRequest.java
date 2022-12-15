package com.google.cloud.pso.bq_pii_classifier.functions.tagger;

import com.google.cloud.bigquery.Table;
import com.google.cloud.pso.bq_pii_classifier.entities.Operation;
import com.google.cloud.pso.bq_pii_classifier.entities.TableSpec;

public class TaggerTableSpecRequest extends Operation {

    private TableSpec targetTable;

    public TaggerTableSpecRequest(String runId, String trackingId, TableSpec targetTable) {
        super(runId, trackingId);
        this.targetTable = targetTable;
    }

    public TableSpec getTargetTable() {
        return targetTable;
    }

    @Override
    public String toString() {
        return "TaggerTableSpecRequest{" +
                "targetTable=" + targetTable +
                "} " + super.toString();
    }
}
