package com.google.cloud.pso.bq_pii_classifier.entities;

import java.util.List;

public record DlpFieldFindings(
    String infoTypeName, List<DlpOtherInfoTypeMatch> otherInfoTypeMatches) {}
