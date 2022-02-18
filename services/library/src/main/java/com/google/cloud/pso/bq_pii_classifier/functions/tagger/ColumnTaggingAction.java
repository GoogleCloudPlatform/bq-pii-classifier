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

package com.google.cloud.pso.bq_pii_classifier.functions.tagger;

public enum ColumnTaggingAction {

    // keep existing policy tag
    // e.g. keep existing manual tagging from an external taxonomy
    KEEP_EXISTING,
    // Overwrite the existing policy tag
    // e.g. previous run detected as STREET_ADDRESS and now as PERSON_NAME (across solution-managed taxonomies)
    OVERWRITE,
    // No change detected in policy tags
    NO_CHANGE,
    // Apply a policy tag to a column without existing tags
    CREATE,

    // Same action logic but without applying the tags to columns (only for logging)
    DRY_RUN_KEEP_EXISTING,
    DRY_RUN_OVERWRITE,
    DRY_RUN_NO_CHANGE,
    DRY_RUN_CREATE
}
