package com.google.cloud.pso.bq_pii_classifier.entities;

import java.util.List;

public record PolicyTagInfo(String infoType, String policyTagId, String classification) {
}
