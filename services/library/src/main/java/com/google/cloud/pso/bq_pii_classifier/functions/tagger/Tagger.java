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
import com.google.cloud.pso.bq_pii_classifier.entities.*;
import com.google.cloud.pso.bq_pii_classifier.helpers.LoggingHelper;
import com.google.cloud.pso.bq_pii_classifier.helpers.Utils;
import com.google.cloud.pso.bq_pii_classifier.services.bq.BigQueryService;
import com.google.cloud.pso.bq_pii_classifier.services.findings.FindingsReader;
import com.google.cloud.pso.bq_pii_classifier.services.set.PersistentSet;
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

    private static final Integer functionNumber = 3;
    private TaggerConfig config;

    BigQueryService bqService;
    FindingsReader findingsReader;
    PersistentSet persistentSet;
    String persistentSetObjectPrefix;

    public Tagger(TaggerConfig config,
                  BigQueryService bqService,
                  FindingsReader findingsReader,
                  PersistentSet persistentSet,
                  String persistentSetObjectPrefix
    ) throws IOException {

        this.config = config;
        this.bqService = bqService;
        this.findingsReader = findingsReader;
        this.persistentSet = persistentSet;
        this.persistentSetObjectPrefix = persistentSetObjectPrefix;

        logger = new LoggingHelper(
                Tagger.class.getSimpleName(),
                functionNumber,
                config.getProjectId()
        );
    }

    public Map<String, String> execute(
            Operation request,
            String pubSubMessageId
    ) throws IOException, InterruptedException, NonRetryableApplicationException {

        logger.logFunctionStart(request.getTrackingId());
        logger.logInfoWithTracker(request.getTrackingId(),
                String.format("Request : %s", request.toString()));

        /**
         *  Check if we already processed this pubSubMessageId before to avoid submitting BQ queries
         *  in case we have unexpected errors with PubSub re-sending the message. This is an extra measure to avoid unnecessary cost.
         *  We do that by keeping simple flag files in GCS with the pubSubMessageId as file name.
         */
        String flagFileName = String.format("%s/%s", persistentSetObjectPrefix, pubSubMessageId);
        if (persistentSet.contains(flagFileName)) {
            // log error and ACK and return
            String msg = String.format("PubSub message ID '%s' has been processed before by the Tagger. The message should be ACK to PubSub to stop retries. Please investigate further why the message was retried in the first place.",
                    pubSubMessageId);
            throw new NonRetryableApplicationException(msg);
        }

        // Query DLP results in BQ and return a dict of bq_column=policy_tag

        // lookup key is the DLP "jobId" in case of Standard Mode (to use the clustered column)
        // and "project.dataset.table" in case of Auto DLP (as there are no jobIds in that case)
        String lookUpKey = request.getEntityKey();

        TablePolicyTags tablePolicyTags = findingsReader.getFieldsToPolicyTagsMap(lookUpKey);

        // TODO: do we really need appliedFieldsToPolicyTags or can we just return tablePolicyTags.getFieldsPolicyTags()
        Map<String, String> appliedFieldsToPolicyTags = new HashMap<>();
        // if we have DLP findings for this table or dlpJob
        if (tablePolicyTags != null) {

            Map<String, PolicyTagInfo> computedFieldsToPolicyTagsMap = tablePolicyTags.getFieldsPolicyTags();
            TableSpec targetTableSpec = tablePolicyTags.getTableSpec();

            // AutoDLP mode and re-tagging runs in Standard mode could potentially contain tables that were deleted.
            // For that we need to check if the table exists before attempting to apply tags
            // When a table is not found a com.google.api.client.googleapis.json.GoogleJsonResponseException
            if (bqService.tableExists(targetTableSpec)) {

                logger.logInfoWithTracker(request.getTrackingId()
                        , String.format("Computed Fields to Policy Tags mapping : %s", computedFieldsToPolicyTagsMap.toString()));

                // Apply policy tags to columns in BigQuery
                // If isDryRun = True no actual tagging will happen on BigQuery and Dry-Run log entries will be written instead
                List<TableFieldSchema> updatedFields = applyPolicyTagsAndLabels(
                        targetTableSpec,
                        computedFieldsToPolicyTagsMap,
                        config.getAppOwnedTaxonomies(),
                        config.getDryRun(),
                        request.getTrackingId());

                appliedFieldsToPolicyTags = mapFieldsToPolicyTags(updatedFields);

            } else {
                // if the table doesn't exist anymore on BigQuery
                logger.logWarnWithTracker(request.getTrackingId(),
                        String.format(
                                "Table %s doesn't exist anymore in BigQuery and no tagging could be applied",
                                targetTableSpec.toSqlString()
                        ));
            }


        } else {
            // if we don't have DLP findings for this table or dlpJob
            logger.logInfoWithTracker(request.getTrackingId(),
                    String.format(
                            "No DLP InfoTypes or mapped policy tags are found for lookUpKey '%s'",
                            lookUpKey
                    ));
        }

        // Add a flag key marking that we already completed this request and no additional runs
        // are required in case PubSub is in a loop of retrying due to ACK timeout while the service has already processed the request
        // This is an extra measure to avoid unnecessary BigQuery cost due to config issues.
        logger.logInfoWithTracker(request.getTrackingId(), String.format("Persisting processing key for PubSub message ID %s", pubSubMessageId));
        persistentSet.add(flagFileName);

        logger.logFunctionEnd(request.getTrackingId());

        return appliedFieldsToPolicyTags;
    }

    private TableFieldSchema updateFieldPolicyTags(TableFieldSchema field,
                                                   String fieldLkpName,
                                                   TableSpec tableSpec,
                                                   Map<String, PolicyTagInfo> fieldsToPolicyTagsMap,
                                                   Set<String> app_managed_taxonomies,
                                                   Boolean isDryRun,
                                                   String trackingId,
                                                   List<TagHistoryLogEntry> policyUpdateLogs
    ) {

        if (fieldsToPolicyTagsMap.containsKey(fieldLkpName)) {

            String newPolicyTagId = fieldsToPolicyTagsMap.get(fieldLkpName).getPolicyTagId().trim();

            PolicyTags fieldPolicyTags = field.getPolicyTags();

            // if no policy exists on the field, attach one
            if (fieldPolicyTags == null) {

                // update the field with policy tag
                fieldPolicyTags = new PolicyTags().setNames(Arrays.asList(newPolicyTagId));
                field.setPolicyTags(fieldPolicyTags);

                TagHistoryLogEntry log = new TagHistoryLogEntry(
                        tableSpec,
                        fieldLkpName,
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
                                fieldLkpName,
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
                                fieldLkpName,
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
                            fieldLkpName,
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

        return field;
    }

    private TableFieldSchema recursiveUpdateFieldPolicyTags(TableFieldSchema field,
                                                            String fieldLkpName,
                                                            TableSpec tableSpec,
                                                            Map<String, PolicyTagInfo> fieldsToPolicyTagsMap,
                                                            Set<String> app_managed_taxonomies,
                                                            Boolean isDryRun,
                                                            String trackingId,
                                                            List<TagHistoryLogEntry> policyUpdateLogs
    ) {

        if (!field.getType().equals("RECORD")) {
            // stop recursion

            // Return the updated field schema with policy tag
            return updateFieldPolicyTags(field,
                    fieldLkpName,
                    tableSpec,
                    fieldsToPolicyTagsMap,
                    app_managed_taxonomies,
                    isDryRun,
                    trackingId,
                    policyUpdateLogs);

        } else {
            // If the field of type RECORD then apply depth-first recursion until you hit a leaf node
            // Then return the updated sub-fields on each level
            List<TableFieldSchema> subFields = field.getFields();
            List<TableFieldSchema> updatedSubFields = new ArrayList<>();

            for (TableFieldSchema subField : subFields) {

                TableFieldSchema updatedSubField = recursiveUpdateFieldPolicyTags(
                        subField,
                        // use mainField.subField as a lookup name for the subField to find it in DLP results
                        String.format("%s.%s", fieldLkpName, subField.getName()),
                        tableSpec,
                        fieldsToPolicyTagsMap,
                        app_managed_taxonomies,
                        isDryRun,
                        trackingId,
                        policyUpdateLogs);

                updatedSubFields.add(updatedSubField);
            }
            return field.setFields(updatedSubFields);
        }
    }

    public List<TableFieldSchema> applyPolicyTagsAndLabels(TableSpec tableSpec,
                                                           Map<String, PolicyTagInfo> fieldsToPolicyTagsMap,
                                                           Set<String> app_managed_taxonomies,
                                                           Boolean isDryRun,
                                                           String trackingId) throws IOException {

        List<TableFieldSchema> currentFields = bqService.getTableSchemaFields(tableSpec);
        List<TableFieldSchema> updatedFields = new ArrayList<>();

        // store all actions on policy tags and log them after patching the BQ table
        List<TagHistoryLogEntry> policyUpdateLogs = new ArrayList<>();

        for (TableFieldSchema mainField : currentFields) {
            TableFieldSchema updatedField = recursiveUpdateFieldPolicyTags(mainField,
                    mainField.getName(),
                    tableSpec,
                    fieldsToPolicyTagsMap,
                    app_managed_taxonomies,
                    isDryRun,
                    trackingId,
                    policyUpdateLogs);

            updatedFields.add(updatedField);
        }

        // construct a map of table labels based on the classification field of each policy tag
        Map<String, String> tableLabels = new HashMap<>();
        for(PolicyTagInfo policyTagInfo: fieldsToPolicyTagsMap.values()){
            // resource labels must be lowercase
            tableLabels.put(policyTagInfo.getClassification().toLowerCase(), "yes");
        }

        // if it's not a dry run, patch the table with the new schema including new policy tags
        if (!isDryRun) {
            bqService.patchTable(tableSpec, updatedFields, tableLabels);
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

}