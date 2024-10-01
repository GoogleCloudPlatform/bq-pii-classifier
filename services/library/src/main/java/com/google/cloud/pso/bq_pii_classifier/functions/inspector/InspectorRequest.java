package com.google.cloud.pso.bq_pii_classifier.functions.inspector;

import com.google.cloud.pso.bq_pii_classifier.entities.Operation;
import com.google.cloud.pso.bq_pii_classifier.entities.TableSpec;

public class InspectorRequest extends Operation {

    private final TableSpec targetTable;
    private final String inspectionTemplate;

    private final String jobRegion;

    public InspectorRequest(String runId,
                            String trackingId,
                            TableSpec targetTable,
                            String inspectionTemplate,
                            String jobRegion) {
        super(runId, trackingId);
        this.targetTable = targetTable;
        this.inspectionTemplate = inspectionTemplate;
        this.jobRegion = jobRegion;
    }

    public TableSpec getTargetTable() {
        return targetTable;
    }

    public String getInspectionTemplate() {
        return inspectionTemplate;
    }

    public String getJobRegion() {
        return jobRegion;
    }

    @Override
    public String toString() {
        return "InspectorRequest{" +
                "targetTable=" + targetTable.toSqlString() +
                ", inspectionTemplate='" + inspectionTemplate + '\'' +
                ", jobRegion='" + jobRegion + '\'' +
                "} " + super.toString();
    }
}
