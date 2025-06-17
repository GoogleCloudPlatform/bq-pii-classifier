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

import com.google.api.services.bigquery.model.TableFieldSchema;
import com.google.cloud.Tuple;
import com.google.cloud.oss.solutions.annotations.entities.DlpFieldFindings;
import com.google.cloud.oss.solutions.annotations.entities.DlpOtherInfoTypeMatch;
import com.google.cloud.oss.solutions.annotations.entities.InfoTypeInfo;
import com.google.cloud.oss.solutions.annotations.entities.NonRetryableApplicationException;
import com.google.cloud.oss.solutions.annotations.entities.PolicyTagInfo;
import com.google.cloud.oss.solutions.annotations.entities.ResourceLabel;
import com.google.cloud.oss.solutions.annotations.entities.ResourceLabelingAction;
import com.google.cloud.oss.solutions.annotations.entities.TableColumnsInfoTypes;
import com.google.cloud.oss.solutions.annotations.entities.TablePolicyTags;
import com.google.cloud.oss.solutions.annotations.entities.TableSpec;
import com.google.cloud.oss.solutions.annotations.entities.TagHistoryLogEntry;
import com.google.cloud.oss.solutions.annotations.entities.dlp.DataProfilePubSubMessage;
import com.google.cloud.oss.solutions.annotations.helpers.LabelsHelper;
import com.google.cloud.oss.solutions.annotations.helpers.LoggingHelper;
import com.google.cloud.oss.solutions.annotations.helpers.Utils;
import com.google.cloud.oss.solutions.annotations.services.bq.BigQueryService;
import com.google.cloud.oss.solutions.annotations.services.findings.DlpFindingsReader;
import java.io.IOException;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Set;
import org.slf4j.event.Level;

/**
 * Main class for the Tagger function.
 *
 * <p>This class is responsible for tagging BigQuery tables with policy tags and labels based on DLP
 * findings.
 */
public class Tagger {

  private static final Integer functionNumber = 3;
  private final LoggingHelper logger;
  private final TaggerConfig config;

  private final BigQueryService bqService;
  private final DlpFindingsReader findingsReader;

  public Tagger(TaggerConfig config, BigQueryService bqService, DlpFindingsReader findingsReader) {

    this.config = config;
    this.bqService = bqService;
    this.findingsReader = findingsReader;

    logger = new LoggingHelper(Tagger.class.getSimpleName(), functionNumber, config.projectId());
  }

  public static Map<String, String> generateTableLabelsFromDlpFindings(
      TablePolicyTags tablePolicyTags, Map<String, InfoTypeInfo> infoTypeMap) {
    Map<String, String> tableLabels = new HashMap<>();
    // loop on all InfoTypes found in that table
    for (PolicyTagInfo policyTagInfo : tablePolicyTags.fieldsPolicyTags().values()) {
      String infoType = policyTagInfo.infoType();
      // lookup the labels associated with that info type based on the classification taxonomy (in
      // Terraform)
      // add each label to the map. Duplicate labels across InfoTypes will be overwritten.
      for (ResourceLabel infoTypeLabel : infoTypeMap.get(infoType).labels()) {
        tableLabels.put(infoTypeLabel.key().toLowerCase(), infoTypeLabel.value().toLowerCase());
      }
    }
    return tableLabels;
  }

  /**
   * Lookup the policy tag id for each info type assigned to a table field
   *
   * @param tableColumnsInfoTypes table columns with assigned info type
   * @param datasetLocation the dataset gcp location of the table
   * @param datasetDomainMap dataset domain mapping config (passed from Terraform)
   * @param projectDomainMap project domain mapping config (passed from Terraform)
   * @param defaultDomainName default domain name config (passed from Terraform)
   * @param infoTypePolicyTagMap info type to policy tag ids map config (passed form Terraform)
   * @return a tuple of 2 elements. First is a Map of fields and their policy tags, second is a
   *     TableColumnsInfoTypes object with the fields/info types that couldn't be matched to policy
   *     tags
   */
  public static Tuple<Map<String, PolicyTagInfo>, TableColumnsInfoTypes> lookupPolicyTags(
      TableColumnsInfoTypes tableColumnsInfoTypes,
      String datasetLocation,
      Map<DatasetDomainMapKey, String> datasetDomainMap,
      Map<String, String> projectDomainMap,
      String defaultDomainName,
      Map<InfoTypePolicyTagMapKey, InfoTypePolicyTagMapValue> infoTypePolicyTagMap) {
    // map each info type to its policy tag and classification for the Tagger
    Map<String, PolicyTagInfo> fieldsPolicyTags = new HashMap<>();
    Map<String, String> unmatchedFields = new HashMap<>();

    for (Map.Entry<String, String> entry : tableColumnsInfoTypes.columnsInfoType().entrySet()) {
      String project = tableColumnsInfoTypes.tableSpec().project();
      String dataset = tableColumnsInfoTypes.tableSpec().dataset();
      String field = entry.getKey();
      String infoType = entry.getValue();

      // get the domain mapping for this dataset and project, if any, to prepare for policy tag
      // lookup
      String domain = null;
      DatasetDomainMapKey datasetDomainMapKey = new DatasetDomainMapKey(project, dataset);
      if (datasetDomainMap.containsKey(datasetDomainMapKey)) {
        domain = datasetDomainMap.get(datasetDomainMapKey);
      } else {
        domain = projectDomainMap.getOrDefault(project, defaultDomainName);
      }

      InfoTypePolicyTagMapValue infoTypePolicyTagMapValue =
          infoTypePolicyTagMap.get(
              new InfoTypePolicyTagMapKey(infoType, datasetLocation.toLowerCase(), domain));

      // if we find a mapping from (info type, location, domain) --> policy tag
      if (infoTypePolicyTagMapValue != null) {
        fieldsPolicyTags.put(
            field,
            new PolicyTagInfo(
                infoType,
                infoTypePolicyTagMapValue.policyTagId(),
                infoTypePolicyTagMapValue.classification()));
      } else {
        // In some cases we won't find a policy tag
        // Case 1: DLP historical findings where the policy tag / info type is not configured in the
        // application anymore
        // Case 2: unexpected errors/bugs in the lookup logic and/or input (e.g. default domain,
        // etc)
        unmatchedFields.put(field, infoType);
      }
    }

    return Tuple.of(
        fieldsPolicyTags,
        new TableColumnsInfoTypes(tableColumnsInfoTypes.tableSpec(), unmatchedFields));
  }

  public static String computeFinalInfoType(
      String mainDlpInfoType,
      List<DlpOtherInfoTypeMatch> otherDlpInfoTypes,
      boolean promoteDlpOtherMatches) {
    if (promoteDlpOtherMatches) {
      // if dlp found a main info type then use it
      if (mainDlpInfoType != null && !mainDlpInfoType.isEmpty()) {
        return mainDlpInfoType;
      } else {
        // if dlp doesn't detect a main info type with high confidence then consider other info
        // types if found
        if (otherDlpInfoTypes != null && otherDlpInfoTypes.size() == 1) {
          return otherDlpInfoTypes.get(0).infoTypeName();
        } else {
          if (otherDlpInfoTypes != null && otherDlpInfoTypes.size() > 1) {
            return "MIXED";
          } else {
            return null;
          }
        }
      }
    } else {
      // if no promotion logic is required then just use the main Dlp info type
      return mainDlpInfoType;
    }
  }

  // entry point for DLP Discovery Service Handler to fetch fields Findings
  public void execute(
      String runId, String trackingId, DataProfilePubSubMessage dataProfilePubSubMessage)
      throws IOException, NonRetryableApplicationException, InterruptedException {

    TableSpec targetTable =
        TableSpec.fromFullResource(dataProfilePubSubMessage.getProfile().getFullResource());

    Map<String, DlpFieldFindings> fieldsFindings =
        findingsReader.getBigQueryDlpProfileSummary(
            dataProfilePubSubMessage.getProfile().getName());

    execute(new TaggerRequest(runId, trackingId, targetTable, fieldsFindings));
  }

  public void execute(TaggerRequest request)
      throws IOException, InterruptedException, NonRetryableApplicationException {

    TableSpec targetTable = request.getTargetTable();

    logger.logFunctionStart(request.getTrackingId(), targetTable.toSqlString());
    logger.logInfoWithTracker(
        request.getTrackingId(), targetTable.toSqlString(), String.format("Request : %s", request));

    // 1. compute final info type per column based on dlp fields findings
    Map<String, String> fieldsFinalFindings = new HashMap<>();
    for (Map.Entry<String, DlpFieldFindings> e : request.getFieldsFindings().entrySet()) {
      String field = e.getKey();
      DlpFieldFindings fieldFindings = e.getValue();
      String finalInfoType =
          computeFinalInfoType(
              fieldFindings.infoTypeName(),
              fieldFindings.otherInfoTypeMatches(),
              config.promoteDlpOtherMatches());

      // only fields with computed info type are required for the tagging flow
      if (finalInfoType != null && !finalInfoType.isEmpty()) {
        fieldsFinalFindings.put(field, finalInfoType);
      }
    }

    logger.logInfoWithTracker(
        request.getTrackingId(),
        targetTable.toSqlString(),
        String.format("Table fields final findings: %s", fieldsFinalFindings));

    String datasetLocation =
        bqService.getDatasetLocation(targetTable.project(), targetTable.dataset());
    TableColumnsInfoTypes tableColumnsInfoTypes =
        new TableColumnsInfoTypes(request.getTargetTable(), fieldsFinalFindings);

    Tuple<Map<String, PolicyTagInfo>, TableColumnsInfoTypes> lookupPolicyTagsResults =
        Tagger.lookupPolicyTags(
            tableColumnsInfoTypes,
            datasetLocation,
            config.datasetDomainMap(),
            config.projectDomainMap(),
            config.defaultDomainName(),
            config.infoTypePolicyTagMap());

    // if some fields had info types detected but no policy tags could be mapped
    if (!lookupPolicyTagsResults.y().columnsInfoType().isEmpty()) {
      logger.logWarnWithTracker(
          request.getTrackingId(),
          targetTable.toSqlString(),
          String.format(
              "The following table fields have assigned info types by DLP but no policy tags could"
                  + " be found for them. Make sure a corresponding policy tag taxonomy is deployed"
                  + " in the same region as the table. Info types and policy tags:  %s ",
              lookupPolicyTagsResults.y().columnsInfoType().toString()));
    }

    // 2. map final info types to TablePolicyTags
    Map<String, PolicyTagInfo> fieldsPolicyTagsInfo = lookupPolicyTagsResults.x();

    logger.logInfoWithTracker(
        request.getTrackingId(),
        targetTable.toSqlString(),
        String.format("Table fields mapped policy tags: %s", fieldsPolicyTagsInfo.toString()));

    TablePolicyTags tablePolicyTags =
        new TablePolicyTags(request.getTargetTable(), fieldsPolicyTagsInfo);

    // if we have DLP findings for this table or dlpJob
    if (tablePolicyTags.fieldsPolicyTags() != null
        && !tablePolicyTags.fieldsPolicyTags().isEmpty()) {

      Map<String, PolicyTagInfo> computedFieldsToPolicyTagsMap = tablePolicyTags.fieldsPolicyTags();
      TableSpec targetTableSpec = tablePolicyTags.tableSpec();

      // a table might have been deleted between the time of DLP execution and (re)tagging
      if (bqService.tableExists(targetTableSpec)) {

        // construct a map of table labels based on the common labels and info type labels
        Map<String, String> tableLabelsFromDlpFindings =
            generateTableLabelsFromDlpFindings(tablePolicyTags, config.infoTypeMap());

        logger.logInfoWithTracker(
            request.getTrackingId(),
            targetTableSpec.toSqlString(),
            String.format(
                "Computed table labels for dlp info types: %s", tableLabelsFromDlpFindings));

        // get existing table labels
        Map<String, String> existingTableLabels = bqService.getTableLabels(targetTableSpec);

        logger.logInfoWithTracker(
            request.getTrackingId(),
            targetTableSpec.toSqlString(),
            String.format("Existing table labels: %s", existingTableLabels));

        Map<Map.Entry<String, String>, ResourceLabelingAction> labelsWithActions =
            LabelsHelper.computeLabelsActions(
                existingTableLabels, tableLabelsFromDlpFindings, config.existingLabelsRegex());

        Map<String, String> tableLabelsToSet =
            LabelsHelper.removeToBeDeletedLabels(labelsWithActions);

        logger.logInfoWithTracker(
            request.getTrackingId(),
            targetTableSpec.toSqlString(),
            String.format("Final labels to be set : %s", tableLabelsToSet));

        // log labels and actions applied on this table
        int deletedLabelsCount = 0;
        int newLabelsCount = 0;
        int modifiedLabelsCount = 0;
        int unchangedLabelsCount = 0;

        for (Map.Entry<Map.Entry<String, String>, ResourceLabelingAction> labelWithAction :
            labelsWithActions.entrySet()) {

          switch (labelWithAction.getValue()) {
            case DELETE -> deletedLabelsCount += 1;
            case NEW_KEY -> newLabelsCount += 1;
            case NEW_VALUE -> modifiedLabelsCount += 1;
            case NO_CHANGE -> unchangedLabelsCount += 1;
          }

          logger.logLabelsHistory(
              targetTableSpec,
              labelWithAction.getKey().getKey(),
              labelWithAction.getKey().getValue(),
              config.isDryRunLabels(),
              labelWithAction.getValue(),
              request.getTrackingId());
        }

        logger.logInfoWithTracker(
            request.getTrackingId(),
            targetTableSpec.toSqlString(),
            String.format(
                "Labels Summary: table = %s, is_dry_run_labels = %s, new labels = %s, changed"
                    + " values = %s, no change = %s, deleted = %s .",
                targetTableSpec.toSqlString(),
                config.isDryRunLabels(),
                newLabelsCount,
                modifiedLabelsCount,
                unchangedLabelsCount,
                deletedLabelsCount));

        // Apply policy tags to columns in BigQuery
        // If isDryRun = True no actual tagging will happen on BigQuery and Dry-Run log entries will
        // be written instead
        applyPolicyTagsAndLabels(
            targetTableSpec,
            computedFieldsToPolicyTagsMap,
            tableLabelsToSet,
            config.appOwnedTaxonomies(),
            config.isDryRunTags(),
            config.isDryRunLabels(),
            request.getTrackingId());

      } else {
        // if the table doesn't exist anymore on BigQuery
        logger.logWarnWithTracker(
            request.getTrackingId(),
            targetTableSpec.toSqlString(),
            String.format(
                "Table %s doesn't exist anymore in BigQuery and no tagging could be applied",
                targetTableSpec.toSqlString()));
      }

    } else {
      // if we don't have DLP findings for this table or dlpJob
      logger.logInfoWithTracker(
          request.getTrackingId(),
          targetTable.toSqlString(),
          String.format(
              "No DLP InfoTypes or mapped policy tags are found for table '%s'",
              targetTable.toSqlString()));
    }

    logger.logFunctionEnd(request.getTrackingId(), targetTable.toSqlString());
  }

  private TableFieldSchema updateFieldPolicyTags(
      TableFieldSchema field,
      String fieldLkpName,
      TableSpec tableSpec,
      Map<String, PolicyTagInfo> fieldsToPolicyTagsMap,
      Set<String> appManagedTaxonomies,
      Boolean isDryRun,
      String trackingId,
      List<TagHistoryLogEntry> policyUpdateLogs) {

    if (fieldsToPolicyTagsMap.containsKey(fieldLkpName)) {

      String newPolicyTagId = fieldsToPolicyTagsMap.get(fieldLkpName).policyTagId().trim();

      TableFieldSchema.PolicyTags fieldPolicyTags = field.getPolicyTags();

      // if no policy exists on the field, attach one
      if (fieldPolicyTags == null) {

        // update the field with policy tag
        fieldPolicyTags = new TableFieldSchema.PolicyTags().setNames(List.of(newPolicyTagId));
        field.setPolicyTags(fieldPolicyTags);

        TagHistoryLogEntry log =
            new TagHistoryLogEntry(
                tableSpec,
                fieldLkpName,
                "",
                newPolicyTagId,
                isDryRun ? ColumnTaggingAction.DRY_RUN_CREATE : ColumnTaggingAction.CREATE,
                "",
                Level.INFO);
        policyUpdateLogs.add(log);
      } else {
        String existingPolicyTagId = fieldPolicyTags.getNames().get(0).trim();

        // overwrite policy tag if it belongs to the same taxonomy only
        String existingTaxonomy = Utils.extractTaxonomyIdFromPolicyTagId(existingPolicyTagId);
        String newTaxonomy = Utils.extractTaxonomyIdFromPolicyTagId(newPolicyTagId);

        // update existing tags only if they belong to the security classifier application.
        // Don't overwrite manually created taxonomies
        if (appManagedTaxonomies.contains(existingTaxonomy)) {

          if (existingPolicyTagId.equals(newPolicyTagId)) {

            // policy tag didn't change
            TagHistoryLogEntry log =
                new TagHistoryLogEntry(
                    tableSpec,
                    fieldLkpName,
                    existingPolicyTagId,
                    newPolicyTagId,
                    isDryRun
                        ? ColumnTaggingAction.DRY_RUN_NO_CHANGE
                        : ColumnTaggingAction.NO_CHANGE,
                    "Existing policy tag is the same as newly computed tag.",
                    Level.INFO);

            policyUpdateLogs.add(log);

          } else {
            // update the field with a new policy tag
            fieldPolicyTags.setNames(List.of(newPolicyTagId));

            TagHistoryLogEntry log =
                new TagHistoryLogEntry(
                    tableSpec,
                    fieldLkpName,
                    existingPolicyTagId,
                    newPolicyTagId,
                    isDryRun
                        ? ColumnTaggingAction.DRY_RUN_OVERWRITE
                        : ColumnTaggingAction.OVERWRITE,
                    "",
                    Level.INFO);
            policyUpdateLogs.add(log);
          }
        } else {

          // if new taxonomy doesn't belong to the BQ security classifier app (e.g. manually
          // created)
          TagHistoryLogEntry log =
              new TagHistoryLogEntry(
                  tableSpec,
                  fieldLkpName,
                  existingPolicyTagId,
                  newPolicyTagId,
                  isDryRun
                      ? ColumnTaggingAction.DRY_RUN_KEEP_EXISTING
                      : ColumnTaggingAction.KEEP_EXISTING,
                  "Can't overwrite tags that are not crated/managed by the application. The"
                      + " existing taxonomy is created by another app/user",
                  Level.WARN);

          policyUpdateLogs.add(log);
        }
      }
    }

    return field;
  }

  private TableFieldSchema recursiveUpdateFieldPolicyTags(
      TableFieldSchema field,
      String fieldLkpName,
      TableSpec tableSpec,
      Map<String, PolicyTagInfo> fieldsToPolicyTagsMap,
      Set<String> appManagedTaxonomies,
      Boolean isDryRun,
      String trackingId,
      List<TagHistoryLogEntry> policyUpdateLogs) {

    if (!field.getType().equals("RECORD")) {
      // stop recursion

      // Return the updated field schema with policy tag
      return updateFieldPolicyTags(
          field,
          fieldLkpName,
          tableSpec,
          fieldsToPolicyTagsMap,
          appManagedTaxonomies,
          isDryRun,
          trackingId,
          policyUpdateLogs);

    } else {
      // If the field of type RECORD then apply depth-first recursion until you hit a leaf node
      // Then return the updated sub-fields on each level
      List<TableFieldSchema> subFields = field.getFields();
      List<TableFieldSchema> updatedSubFields = new ArrayList<>();

      for (TableFieldSchema subField : subFields) {

        TableFieldSchema updatedSubField =
            recursiveUpdateFieldPolicyTags(
                subField,
                // use mainField.subField as a lookup name for the subField to find it in DLP
                // results
                String.format("%s.%s", fieldLkpName, subField.getName()),
                tableSpec,
                fieldsToPolicyTagsMap,
                appManagedTaxonomies,
                isDryRun,
                trackingId,
                policyUpdateLogs);

        updatedSubFields.add(updatedSubField);
      }
      return field.setFields(updatedSubFields);
    }
  }

  public List<TableFieldSchema> applyPolicyTagsAndLabels(
      TableSpec tableSpec,
      Map<String, PolicyTagInfo> fieldsToPolicyTagsMap,
      Map<String, String> tableLabels,
      Set<String> appManagedTaxonomies,
      Boolean isDryRunTags,
      Boolean isDryRunLabels,
      String trackingId)
      throws IOException {

    List<TableFieldSchema> currentFields = bqService.getTableSchemaFields(tableSpec);
    List<TableFieldSchema> updatedFields = new ArrayList<>();

    // store all actions on policy tags and log them after patching the BQ table
    List<TagHistoryLogEntry> policyUpdateLogs = new ArrayList<>();

    for (TableFieldSchema mainField : currentFields) {
      TableFieldSchema updatedField =
          recursiveUpdateFieldPolicyTags(
              mainField,
              mainField.getName(),
              tableSpec,
              fieldsToPolicyTagsMap,
              appManagedTaxonomies,
              isDryRunTags,
              trackingId,
              policyUpdateLogs);

      updatedFields.add(updatedField);
    }

    // if this is a wet run for both tags and labels, patch them in one request
    if (!isDryRunTags && !isDryRunLabels) {
      // bqService.patchTable(tableSpec, updatedFields, tableLabels);
      bqService.patchTableSchema(tableSpec, updatedFields);
      bqService.overWriteTableLabels(tableSpec, tableLabels);

      String msg =
          String.format(
              "Policy tags and resource labels applied to table %s.", tableSpec.toSqlString());
      logger.logInfoWithTracker(trackingId, tableSpec.toSqlString(), msg);
    } else {
      if (!isDryRunTags && isDryRunLabels) {
        bqService.patchTableSchema(tableSpec, updatedFields);
        String msg = String.format("Policy tags applied to table %s.", tableSpec.toSqlString());
        logger.logInfoWithTracker(trackingId, tableSpec.toSqlString(), msg);
      }
      if (isDryRunTags && !isDryRunLabels) {
        // bqService.patchTableLabels(tableSpec, tableLabels);
        bqService.overWriteTableLabels(tableSpec, tableLabels);
        String msg = String.format("Resource labels applied to table %s.", tableSpec.toSqlString());
        logger.logInfoWithTracker(trackingId, tableSpec.toSqlString(), msg);
      }
      if (isDryRunTags && isDryRunLabels) {
        String msg =
            String.format(
                "No policy tags or resource labels will be applied to table %s."
                    + " Both isDryRunTags and isDryRunLabels are set to True",
                tableSpec.toSqlString());
        logger.logInfoWithTracker(trackingId, tableSpec.toSqlString(), msg);
      }
    }

    // log all actions on policy tags after bq.tables.patch operation is successful
    for (TagHistoryLogEntry l : policyUpdateLogs) {
      logger.logTagHistory(l, trackingId);
    }

    return updatedFields;
  }
}
