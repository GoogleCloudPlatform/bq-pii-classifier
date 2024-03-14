package com.google.cloud.pso.bq_pii_classifier.entities;

public class PolicyTagInfo {

    private final String infoType;
    private final String policyTagId;
    private final String classification;

    public PolicyTagInfo(String infoType, String policyTagId, String classification) {
        this.infoType = infoType;
        this.policyTagId = policyTagId;
        this.classification = classification;
    }

    public String getInfoType() {
        return infoType;
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
                "infoType='" + infoType + '\'' +
                ", policyTagId='" + policyTagId + '\'' +
                ", classification='" + classification + '\'' +
                '}';
    }
}
