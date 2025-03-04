package com.google.cloud.pso.bq_pii_classifier.helpers;

public record ThrowableInfo(Throwable throwable, boolean isRetryable, String notes) { }
