package com.google.cloud.pso.bq_pii_classifier.functions.tagger;

import com.google.cloud.pso.bq_pii_classifier.entities.DlpFieldFindings;
import com.google.cloud.pso.bq_pii_classifier.entities.Operation;
import com.google.cloud.pso.bq_pii_classifier.entities.TableSpec;
import com.google.common.base.Objects;
import java.util.Map;

public class TaggerRequest extends Operation {

  private final TableSpec targetTable;

  private final Map<String, DlpFieldFindings> fieldsFindings;

  public TaggerRequest(
      String runId,
      String trackingId,
      TableSpec targetTable,
      Map<String, DlpFieldFindings> fieldsFindings) {
    super(runId, trackingId);
    this.targetTable = targetTable;
    this.fieldsFindings = fieldsFindings;
  }

  public TableSpec getTargetTable() {
    return targetTable;
  }

  public Map<String, DlpFieldFindings> getFieldsFindings() {
    return fieldsFindings;
  }

  @Override
  public String toString() {
    return "TaggerRequest{"
        + "targetTable="
        + targetTable
        + ", fieldsFindings="
        + fieldsFindings
        + "} "
        + super.toString();
  }

  @Override
  public boolean equals(Object o) {
    if (this == o) return true;
    if (o == null || getClass() != o.getClass()) return false;
    TaggerRequest that = (TaggerRequest) o;
    return Objects.equal(targetTable, that.targetTable)
        && Objects.equal(fieldsFindings, that.fieldsFindings);
  }

  @Override
  public int hashCode() {
    return Objects.hashCode(targetTable, fieldsFindings);
  }
}
