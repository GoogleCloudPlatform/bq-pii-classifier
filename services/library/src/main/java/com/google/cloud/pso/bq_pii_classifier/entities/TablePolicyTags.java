package com.google.cloud.pso.bq_pii_classifier.entities;

import java.util.Map;

public class TablePolicyTags {

    private TableSpec tableSpec;
    private Map<String, String> fieldsPolicyTags;


    public TablePolicyTags(TableSpec tableSpec, Map<String, String> fieldsPolicyTags) {
        this.tableSpec = tableSpec;
        this.fieldsPolicyTags = fieldsPolicyTags;
    }

    public TableSpec getTableSpec() {
        return tableSpec;
    }

    public Map<String, String> getFieldsPolicyTags() {
        return fieldsPolicyTags;
    }

    @Override
    public String toString() {
        return "TablePolicyTags{" +
                "tableSpec=" + tableSpec +
                ", fieldsPolicyTags=" + fieldsPolicyTags +
                '}';
    }
}
