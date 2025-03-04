package com.google.cloud.pso.bq_pii_classifier.functions.tagger;

import com.google.cloud.pso.bq_pii_classifier.entities.Operation;
import com.google.cloud.pso.bq_pii_classifier.entities.TablePolicyTags;
import com.google.common.base.Objects;

public class TaggerRequest extends Operation {

    public final TablePolicyTags tablePolicyTags;

    public TaggerRequest(String runId, String trackingId, TablePolicyTags tablePolicyTags) {
        super(runId, trackingId);
        this.tablePolicyTags = tablePolicyTags;
    }

    public TablePolicyTags getTablePolicyTags() {
        return tablePolicyTags;
    }

    @Override
    public String toString() {
        return "TaggerRequest{" +
                "tablePolicyTags=" + tablePolicyTags +
                "} " + super.toString();
    }

    @Override
    public boolean equals(Object o) {
        if (this == o) return true;
        if (o == null || getClass() != o.getClass()) return false;
        TaggerRequest that = (TaggerRequest) o;
        return Objects.equal(tablePolicyTags, that.tablePolicyTags);
    }

    @Override
    public int hashCode() {
        return Objects.hashCode(tablePolicyTags);
    }
}
