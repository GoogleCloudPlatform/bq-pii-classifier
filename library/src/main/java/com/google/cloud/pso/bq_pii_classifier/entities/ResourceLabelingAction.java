package com.google.cloud.pso.bq_pii_classifier.entities;

public enum ResourceLabelingAction {
  // new key-value pair
  NEW_KEY,
  // existing key, new value
  NEW_VALUE,
  // key-value pair not changed
  NO_CHANGE,
  // key-value pair deleted
  DELETE
}
