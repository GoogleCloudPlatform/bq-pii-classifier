package com.google.cloud.pso.bq_pii_classifier.services.findings;

import com.google.cloud.bigquery.FieldValueList;
import com.google.cloud.bigquery.Job;
import com.google.cloud.bigquery.TableResult;
import com.google.cloud.pso.bq_pii_classifier.entities.NonRetryableApplicationException;
import com.google.cloud.pso.bq_pii_classifier.entities.TablePolicyTags;
import com.google.cloud.pso.bq_pii_classifier.entities.TableSpec;
import com.google.cloud.pso.bq_pii_classifier.services.bq.BigQueryService;
import com.google.common.io.Resources;

import java.io.IOException;
import java.net.URL;
import java.nio.charset.StandardCharsets;
import java.util.HashMap;
import java.util.Map;

public class FindingsReaderAutoDlp implements FindingsReader {

    private BigQueryService bqService;
    private String dlpProject;

    public FindingsReaderAutoDlp(BigQueryService bqService, String dlpProject, String dlpDataset, String dlpTable, String datasetDomainMapView, String projectDomainMapView, String infoTypesPolicyTagsMapView) {
        this.bqService = bqService;
        this.dlpProject = dlpProject;
        this.dlpDataset = dlpDataset;
        this.dlpTable = dlpTable;
        this.datasetDomainMapView = datasetDomainMapView;
        this.projectDomainMapView = projectDomainMapView;
        this.infoTypesPolicyTagsMapView = infoTypesPolicyTagsMapView;
    }

    private String dlpDataset;
    private String dlpTable;
    private String datasetDomainMapView;
    private String projectDomainMapView;
    private String infoTypesPolicyTagsMapView;



    // inspectedTableSpec:  "project.dataset.table"
    private String generateQuery(String inspectedTableSpec) throws IOException {

        String sqlTemplatePath = "sql/v_dlp_fields_findings_auto_dlp.tpl";

        final URL url = Resources.getResource(sqlTemplatePath);

        String queryTemplate = Resources.toString(url, StandardCharsets.UTF_8);

        return queryTemplate.replace("${project}", dlpProject)
                .replace("${dataset}", dlpDataset)
                .replace("${config_view_infotypes_policytags_map}", infoTypesPolicyTagsMapView)
                .replace("${config_view_dataset_domain_map}", datasetDomainMapView)
                .replace("${config_view_project_domain_map}", projectDomainMapView)
                .replace("${results_table}", dlpTable)
                .replace("${param_lookup_key}", inspectedTableSpec);
    }

    /**
     * Look for DLP results by a tableSpec. Returns a map of fields to policy tags or null if DLP
     * doesn't have findings
     *
     * @param inspectedTableSpec: "project.dataset.table"
     * @return
     * @throws InterruptedException
     * @throws NonRetryableApplicationException
     * @throws IOException
     */
    public TablePolicyTags getFieldsToPolicyTagsMap(String inspectedTableSpec) throws InterruptedException, NonRetryableApplicationException, IOException {

        String formattedQuery = generateQuery(inspectedTableSpec);

        // Create a job ID so that we can safely retry.
        Job queryJob = bqService.submitJob(formattedQuery);

        TableResult result = bqService.waitAndGetJobResults(queryJob);

        // Construct a mapping between field names and DLP infotypes
        Map<String, String> fieldsToPolicyTagMap = new HashMap<>();
        for (FieldValueList row : result.iterateAll()) {

            if (row.get("field_name").isNull()) {
                throw new NonRetryableApplicationException("getFieldsToPolicyTagsMap query returned rows with null field_name");
            }
            String column_name = row.get("field_name").getStringValue();

            if (row.get("info_type").isNull()) {
                throw new NonRetryableApplicationException(
                        String.format(
                                "getFieldsToPolicyTagsMap query returned rows with null info_type for column '%s'",
                                column_name));
            }
            String info_type = row.get("info_type").getStringValue();

            if (row.get("policy_tag").isNull()) {
                throw new NonRetryableApplicationException(
                        String.format(
                                "getFieldsToPolicyTagsMap query returned rows with null policy_tag for column '%s' of info_type '%s'. Checkout the classification taxonomy configuration and the DLP inspection template. All InfoTypes defined in the inspection template must have corresponding entries in the classification taxonomies.",
                                column_name, info_type));
            }
            String policy_tag = row.get("policy_tag").getStringValue();

            fieldsToPolicyTagMap.put(column_name, policy_tag);
        }

        if (fieldsToPolicyTagMap.isEmpty())
            return null;
        else
            return new TablePolicyTags(TableSpec.fromSqlString(inspectedTableSpec), fieldsToPolicyTagMap);
    }


}
