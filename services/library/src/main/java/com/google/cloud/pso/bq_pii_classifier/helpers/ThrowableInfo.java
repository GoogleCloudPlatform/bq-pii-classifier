package com.google.cloud.pso.bq_pii_classifier.helpers;

public class ThrowableInfo {

    private Throwable throwable;
    private boolean isRetryable;
    private String notes;

    public ThrowableInfo(Throwable throwable, boolean isRetryable, String notes) {
        this.throwable = throwable;
        this.isRetryable = isRetryable;
        this.notes = notes;
    }

    public Throwable getThrowable() {
        return throwable;
    }

    public boolean isRetryable() {
        return isRetryable;
    }

    public String getNotes() {
        return notes;
    }

    @Override
    public String toString() {
        return "ThrowableInfo{" +
                "exception=" + throwable +
                ", isRetryable=" + isRetryable +
                ", notes='" + notes + '\'' +
                '}';
    }
}
