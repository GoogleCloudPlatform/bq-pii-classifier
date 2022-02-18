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

import com.google.api.services.bigquery.model.TableFieldSchema;
import com.google.api.services.bigquery.model.TableFieldSchema.PolicyTags;
import com.google.cloud.bigquery.FieldValueList;
import com.google.cloud.bigquery.Job;
import com.google.cloud.bigquery.TableResult;
import com.google.cloud.pso.bq_pii_classifier.entities.NonRetryableApplicationException;
import com.google.cloud.pso.bq_pii_classifier.entities.TableOperationRequest;
import com.google.cloud.pso.bq_pii_classifier.entities.TableSpec;
import com.google.cloud.pso.bq_pii_classifier.entities.TagHistoryLogEntry;
import com.google.cloud.pso.bq_pii_classifier.helpers.LoggingHelper;
import com.google.cloud.pso.bq_pii_classifier.helpers.Utils;
import com.google.cloud.pso.bq_pii_classifier.services.BigQueryService;
import org.slf4j.event.Level;

import java.io.IOException;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Set;

public class Tagger {

    private final LoggingHelper logger;

    private static final Integer functionNumber = 4;
    private TaggerConfig config;

    BigQueryService bqService;

    public Tagger(TaggerConfig config, BigQueryService bqService) throws IOException {

        this.config = config;
        this.bqService = bqService;

        logger = new LoggingHelper(
                Tagger.class.getSimpleName(),
                functionNumber,
                config.getProjectId()
                );
    }

    public Map<String, String> execute(
            TableOperationRequest request,
            String trackingId
            ) throws IOException, InterruptedException, NonRetryableApplicationException {

        logger.logFunctionStart(trackingId);

        logger.logInfoWithTracker(trackingId, String.format("Request : %s", request.toString()));

        TableSpec targetTableSpec = TableSpec.fromSqlString(request.getTableSpec());

        // Query DLP results in BQ and return a dict of bq_column=policy_tag
        Map<String, String> fieldsToPolicyTagsMap = getFieldsToPolicyTagsMap(
                config.getBqViewFieldsFindings(),
                targetTableSpec);


        logger.logInfoWithTracker(trackingId, String.format("Computed Fields to Policy Tags mapping : %s", fieldsToPolicyTagsMap.toString()));

        Map<String, String> fieldsToPolicyTags = new HashMap<>();

        // If there is PII and mapped policy tags found
        if (!fieldsToPolicyTagsMap.isEmpty()){

            // Apply policy tags to columns in BigQuery
            // If isDryRun = True no actual tagging will happen on BogQuery and Dry-Run log entries will be written instead
            List<TableFieldSchema> updatedFields = applyPolicyTags(
                    targetTableSpec,
                    fieldsToPolicyTagsMap,
                    config.getAppOwnedTaxonomies(),
                    config.getDryRun(),
                    trackingId);

            fieldsToPolicyTags = mapFieldsToPolicyTags(updatedFields);
        }else{
            logger.logInfoWithTracker(trackingId,
                    String.format(
                            "No DLP InfoTypes or mapped policy tags are found for table '%s' in DLP results view '%s'",
                            request.getTableSpec(),
                            config.getBqViewFieldsFindings()
                            ));
        }

        logger.logFunctionEnd(trackingId);

        return fieldsToPolicyTags;
    }

    public List<TableFieldSchema> applyPolicyTags(TableSpec tableSpec,
                                                  Map<String, String> fieldsToPolicyTagsMap,
                                                  Set<String> app_managed_taxonomies,
                                                  Boolean isDryRun,
                                                  String trackingId) throws IOException {

        List<TableFieldSchema> currentFields = bqService.getTableSchemaFields(tableSpec);
        List<TableFieldSchema> updatedFields = new ArrayList<>();

        // store all actions on policy tags and log them after patching the BQ table
        List<TagHistoryLogEntry> policyUpdateLogs = new ArrayList<>();

        for (TableFieldSchema field : currentFields) {
            if (fieldsToPolicyTagsMap.containsKey(field.getName())) {

                String newPolicyTagId = fieldsToPolicyTagsMap.get(field.getName()).trim();

                PolicyTags fieldPolicyTags = field.getPolicyTags();

                // if no policy exists on the field, attach one
                if (fieldPolicyTags == null) {

                    // update the field with policy tag
                    fieldPolicyTags = new PolicyTags().setNames(Arrays.asList(newPolicyTagId));
                    field.setPolicyTags(fieldPolicyTags);

                    TagHistoryLogEntry log = new TagHistoryLogEntry(
                            tableSpec,
                            field.getName(),
                            "",
                            newPolicyTagId,
                            isDryRun ? ColumnTaggingAction.DRY_RUN_CREATE : ColumnTaggingAction.CREATE,
                            "",
                            Level.INFO
                    );
                    policyUpdateLogs.add(log);
                } else {
                    String existingPolicyTagId = fieldPolicyTags.getNames().get(0).trim();

                    // overwrite policy tag if it belongs to the same taxonomy only
                    String existingTaxonomy = Utils.extractTaxonomyIdFromPolicyTagId(existingPolicyTagId);
                    String newTaxonomy = Utils.extractTaxonomyIdFromPolicyTagId(newPolicyTagId);

                    // update existing tags only if they belong to the security classifier application.
                    // Don't overwrite manually created taxonomies
                    if (app_managed_taxonomies.contains(existingTaxonomy)) {

                        if (existingPolicyTagId.equals(newPolicyTagId)) {

                            // policy tag didn't change
                            TagHistoryLogEntry log = new TagHistoryLogEntry(
                                    tableSpec,
                                    field.getName(),
                                    existingPolicyTagId,
                                    newPolicyTagId,
                                    isDryRun ? ColumnTaggingAction.DRY_RUN_NO_CHANGE : ColumnTaggingAction.NO_CHANGE,
                                    "Existing policy tag is the same as newly computed tag.",
                                    Level.INFO
                            );

                            policyUpdateLogs.add(log);

                        } else {
                            // update the field with a new policy tag
                            fieldPolicyTags.setNames(Arrays.asList(newPolicyTagId));

                            TagHistoryLogEntry log = new TagHistoryLogEntry(
                                    tableSpec,
                                    field.getName(),
                                    existingPolicyTagId,
                                    newPolicyTagId,
                                    isDryRun ? ColumnTaggingAction.DRY_RUN_OVERWRITE : ColumnTaggingAction.OVERWRITE,
                                    "",
                                    Level.INFO
                            );
                            policyUpdateLogs.add(log);
                        }
                    } else {

                        // if new taxonomy doesn't belong to the BQ security classifier app (e.g. manually created)
                        TagHistoryLogEntry log = new TagHistoryLogEntry(
                                tableSpec,
                                field.getName(),
                                existingPolicyTagId,
                                newPolicyTagId,
                                isDryRun ? ColumnTaggingAction.DRY_RUN_KEEP_EXISTING : ColumnTaggingAction.KEEP_EXISTING,
                                "Can't overwrite tags that are not crated/managed by the application. The existing taxonomy is created by another app/user",
                                Level.WARN
                        );

                        policyUpdateLogs.add(log);
                    }
                }
            }
            // add all fields that exists in the table (after updates) to be able to patch the table
            updatedFields.add(field);
        }

        // if it's not a dry run, patch the table with the new schema including new policy tags
        if (!isDryRun) {
            bqService.patchTable(tableSpec, updatedFields);
        }


        // log all actions on policy tags after bq.tables.patch operation is successful
        for (TagHistoryLogEntry l : policyUpdateLogs) {
            logger.logTagHistory(l, trackingId);
        }

        return updatedFields;
    }

    public Map<String, String> mapFieldsToPolicyTags(List<TableFieldSchema> fields) {
        Map<String, String> result = new HashMap<>();
        for (TableFieldSchema field : fields) {
            PolicyTags policyTags = field.getPolicyTags();
            if (policyTags == null) {
                result.put(field.getName(), "");
            } else {
                // only one policy tag per column is allowed by BigQuery
                result.put(field.getName(), policyTags.getNames().get(0));
            }
        }
        return result;
    }

    public Map<String, String> getFieldsToPolicyTagsMap(String filedsToInfoTypeFindingsViewSpec,
                                                        TableSpec targetTableSpec) throws InterruptedException, NonRetryableApplicationException {


        String formattedQuery = String.format(
                "SELECT field_name, info_type, policy_tag FROM `%s` WHERE table_spec = '%s' AND info_type IS NOT NULL",
                filedsToInfoTypeFindingsViewSpec,
                targetTableSpec.toSqlString()
        );

        // Create a job ID so that we can safely retry.
        Job queryJob = bqService.submitJob(formattedQuery);

        TableResult result = bqService.waitAndGetJobResults(queryJob);

        // Construct a mapping between field names and DLP infotypes
        Map<String, String> fieldsToPolicyTagMap = new HashMap<>();
        for (FieldValueList row : result.iterateAll()) {

            if (row.get("field_name").isNull()){
                throw new NonRetryableApplicationException("getFieldsToPolicyTagsMap query returned rows with null field_name");
            }
            String column_name = row.get("field_name").getStringValue();

            if (row.get("info_type").isNull()){
                throw new NonRetryableApplicationException(
                        String.format(
                                "getFieldsToPolicyTagsMap query returned rows with null info_type for column '%s'",
                                column_name));
            }
            String info_type = row.get("info_type").getStringValue();

            if (row.get("policy_tag").isNull()){
                throw new NonRetryableApplicationException(
                        String.format(
                                "getFieldsToPolicyTagsMap query returned rows with null policy_tag for column '%s' of info_type '%s'. Checkout the classification taxonomy configuration and the DLP inspection template. All InfoTypes defined in the inspection template must have corresponding entries in the classification taxonomies.",
                                column_name, info_type));
            }
            String policy_tag = row.get("policy_tag").getStringValue();

            fieldsToPolicyTagMap.put(column_name, policy_tag);
        }

        return fieldsToPolicyTagMap;
    }

}