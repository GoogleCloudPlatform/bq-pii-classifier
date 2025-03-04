package com.google.cloud.pso.bq_pii_classifier.entities;

import java.util.Map;

public record TableColumnsInfoTypes(TableSpec tableSpec, Map<String, String> columnsInfoType) {
}
