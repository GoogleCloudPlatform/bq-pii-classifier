package com.google.cloud.pso.bq_pii_classifier.entities;

import java.util.Map;

public class TablePolicyTags {

    private TableSpec tableSpec;
    private Map<String, PolicyTagInfo> fieldsPolicyTags;


    public TablePolicyTags(TableSpec tableSpec, Map<String, PolicyTagInfo> fieldsPolicyTags) {
        this.tableSpec = tableSpec;
        this.fieldsPolicyTags = fieldsPolicyTags;
    }

    public TableSpec getTableSpec() {
        return tableSpec;
    }

    public Map<String, PolicyTagInfo> getFieldsPolicyTags() {
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
