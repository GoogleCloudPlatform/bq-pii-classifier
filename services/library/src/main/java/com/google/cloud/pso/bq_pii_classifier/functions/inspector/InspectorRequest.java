package com.google.cloud.pso.bq_pii_classifier.functions.inspector;

import com.google.cloud.pso.bq_pii_classifier.entities.Operation;
import com.google.cloud.pso.bq_pii_classifier.entities.TableSpec;

public class InspectorRequest extends Operation {

    private TableSpec targetTable;
    private String inspectionTemplate;

    public InspectorRequest(String runId, String trackingId, TableSpec targetTable, String inspectionTemplate) {
        super(runId, trackingId);
        this.targetTable = targetTable;
        this.inspectionTemplate = inspectionTemplate;
    }

    public TableSpec getTargetTable() {
        return targetTable;
    }

    public String getInspectionTemplate() {
        return inspectionTemplate;
    }

    @Override
    public String toString() {
        return "InspectorRequest{" +
                "targetTable=" + targetTable +
                ", inspectionTemplate='" + inspectionTemplate + '\'' +
                "} " + super.toString();
    }
}
