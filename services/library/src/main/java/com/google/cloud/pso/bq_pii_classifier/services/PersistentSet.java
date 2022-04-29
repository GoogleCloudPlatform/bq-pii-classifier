package com.google.cloud.pso.bq_pii_classifier.services;

public interface PersistentSet {

    void add(String key);
    boolean contains(String key);
}
