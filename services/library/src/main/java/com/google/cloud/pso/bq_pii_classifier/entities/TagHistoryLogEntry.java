/*
 * Copyright 2022 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     https://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

package com.google.cloud.pso.bq_pii_classifier.entities;

import com.google.cloud.pso.bq_pii_classifier.functions.tagger.ColumnTaggingAction;
import org.slf4j.event.Level;

public class TagHistoryLogEntry {

    private TableSpec tableSpec;
    private String fieldName;
    private String existingPolicyTagId;
    private String newPolicyTagId;
    private ColumnTaggingAction columnTaggingAction;
    private String description;
    private Level logLevel;

    public TagHistoryLogEntry(TableSpec tableSpec, String fieldName, String existingPolicyTagId, String newPolicyTagId, ColumnTaggingAction columnTaggingAction, String description, Level logLevel) {
        this.tableSpec = tableSpec;
        this.fieldName = fieldName;
        this.existingPolicyTagId = existingPolicyTagId;
        this.newPolicyTagId = newPolicyTagId;
        this.columnTaggingAction = columnTaggingAction;
        this.description = description;
        this.logLevel = logLevel;
    }

    public String getFieldName() {
        return fieldName;
    }

    public String getExistingPolicyTagId() {
        return existingPolicyTagId;
    }

    public String getNewPolicyTagId() {
        return newPolicyTagId;
    }

    public ColumnTaggingAction getColumnTaggingAction() {
        return columnTaggingAction;
    }

    public String getDescription() {
        return description;
    }

    public Level getLogLevel() {
        return logLevel;
    }

    public TableSpec getTableSpec() {
        return tableSpec;
    }

    public String toLogString() {

        return String.format("%s | %s | %s | %s | %s | %s | %s | %s",
                tableSpec.getProject(),
                tableSpec.getDataset(),
                tableSpec.getTable(),
                fieldName,
                existingPolicyTagId,
                newPolicyTagId,
                columnTaggingAction,
                description
        );
    }
}
