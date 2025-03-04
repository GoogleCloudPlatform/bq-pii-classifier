package com.google.cloud.pso.bq_pii_classifier.entities;

public record ResourceLabel(String key, String value) {

    @Override
    public String toString() {
        return "ResourceLabel{" +
                "key='" + key + '\'' +
                ", value='" + value + '\'' +
                '}';
    }
}
