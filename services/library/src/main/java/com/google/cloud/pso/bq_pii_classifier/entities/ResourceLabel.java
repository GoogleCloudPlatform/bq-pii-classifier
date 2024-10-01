package com.google.cloud.pso.bq_pii_classifier.entities;

public class ResourceLabel {
    private String key;
    private String value;

    public ResourceLabel(String key, String value) {
        this.key = key;
        this.value = value;
    }

    public String getKey() {
        return key;
    }

    public String getValue() {
        return value;
    }

    @Override
    public String toString() {
        return "ResourceLabel{" +
                "key='" + key + '\'' +
                ", value='" + value + '\'' +
                '}';
    }
}
