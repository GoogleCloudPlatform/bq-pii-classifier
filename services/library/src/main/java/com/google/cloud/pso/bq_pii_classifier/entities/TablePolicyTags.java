package com.google.cloud.pso.bq_pii_classifier.entities;

import java.util.Map;

public record TablePolicyTags(TableSpec tableSpec,
                              Map<String, PolicyTagInfo> fieldsPolicyTags) {
}
