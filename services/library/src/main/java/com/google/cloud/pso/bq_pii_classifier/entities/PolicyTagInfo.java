package com.google.cloud.pso.bq_pii_classifier.entities;

public class PolicyTagInfo {

    private final String policyTagId;
    private final String classification;

    public PolicyTagInfo(String policyTagId, String classification) {
        this.policyTagId = policyTagId;
        this.classification = classification;
    }

    public String getPolicyTagId() {
        return policyTagId;
    }

    public String getClassification() {
        return classification;
    }

    @Override
    public String toString() {
        return "PolicyTagInfo{" +
                "policyTagId='" + policyTagId + '\'' +
                ", classification='" + classification + '\'' +
                '}';
    }
}
