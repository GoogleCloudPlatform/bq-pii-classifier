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

import com.google.cloud.oss.solutions.annotations.entities.InfoTypeInfo;
import java.util.Map;
import java.util.Set;

/**
 * Configuration for the Tagger function.
 *
 * @param projectId The project ID of the GCP project.
 * @param appOwnedTaxonomies The set of taxonomies owned by the application.
 * @param isDryRunTags Whether to dry run the tagging process.
 * @param isDryRunLabels Whether to dry run the labeling process.
 * @param infoTypeMap The map of info types to their info.
 * @param existingLabelsRegex The regex for existing labels.
 * @param promoteDlpOtherMatches Whether to promote DLP other matches.
 * @param infoTypePolicyTagMap The map of info types to their policy tags.
 * @param projectDomainMap The map of projects to their domains.
 * @param datasetDomainMap The map of datasets to their domains.
 * @param defaultDomainName The default domain name.
 */
public record TaggerConfig(
    String projectId,
    Set<String> appOwnedTaxonomies,
    Boolean isDryRunTags,
    Boolean isDryRunLabels,
    Map<String, InfoTypeInfo> infoTypeMap,
    String existingLabelsRegex,
    Boolean promoteDlpOtherMatches,
    Map<InfoTypePolicyTagMapKey, InfoTypePolicyTagMapValue> infoTypePolicyTagMap,
    Map<String, String> projectDomainMap,
    Map<DatasetDomainMapKey, String> datasetDomainMap,
    String defaultDomainName) {}
