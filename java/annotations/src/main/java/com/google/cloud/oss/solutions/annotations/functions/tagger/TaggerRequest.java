/*
 *
 *  Copyright 2025 Google LLC
 *
 *  Licensed under the Apache License, Version 2.0 (the "License");
 *  you may not use this file except in compliance with the License.
 *  You may obtain a copy of the License at
 *
 *       https://www.apache.org/licenses/LICENSE-2.0
 *
 *  Unless required by applicable law or agreed to in writing, software
 *  distributed under the License is distributed on an "AS IS" BASIS,
 *  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or
 *  implied.
 *  See the License for the specific language governing permissions and
 *  limitations under the License.
 *
 */

package com.google.cloud.oss.solutions.annotations.functions.tagger;

import com.google.common.base.Objects;
import com.google.cloud.oss.solutions.annotations.entities.DlpFieldFindings;
import com.google.cloud.oss.solutions.annotations.entities.Operation;
import com.google.cloud.oss.solutions.annotations.entities.TableSpec;
import java.util.Map;

/** Represents a request to tag a table with DLP findings. */
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
    if (this == o) {
      return true;
    }
    if (o == null || getClass() != o.getClass()) {
      return false;
    }
    TaggerRequest that = (TaggerRequest) o;
    return Objects.equal(targetTable, that.targetTable)
        && Objects.equal(fieldsFindings, that.fieldsFindings);
  }

  @Override
  public int hashCode() {
    return Objects.hashCode(targetTable, fieldsFindings);
  }
}
