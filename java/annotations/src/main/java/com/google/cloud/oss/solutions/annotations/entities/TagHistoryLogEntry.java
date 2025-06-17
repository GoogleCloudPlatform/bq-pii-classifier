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

package com.google.cloud.oss.solutions.annotations.entities;

import com.google.cloud.oss.solutions.annotations.functions.tagger.ColumnTaggingAction;
import org.slf4j.event.Level;

/** Represents a log entry for a tag history. */
public record TagHistoryLogEntry(
    TableSpec tableSpec,
    String fieldName,
    String existingPolicyTagId,
    String newPolicyTagId,
    ColumnTaggingAction columnTaggingAction,
    String description,
    Level logLevel) {

  /**
   * Converts the log entry to a string.
   *
   * @return a string representation of the log entry.
   */
  public String toLogString() {

    return String.format(
        "%s | %s | %s | %s | %s | %s | %s | %s",
        tableSpec.project(),
        tableSpec.dataset(),
        tableSpec.table(),
        fieldName,
        existingPolicyTagId,
        newPolicyTagId,
        columnTaggingAction,
        description);
  }
}
