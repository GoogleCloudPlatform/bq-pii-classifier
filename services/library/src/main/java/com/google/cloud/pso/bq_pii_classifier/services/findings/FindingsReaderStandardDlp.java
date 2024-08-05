package com.google.cloud.pso.bq_pii_classifier.services.findings;

import com.google.cloud.bigquery.FieldValueList;
import com.google.cloud.bigquery.Job;
import com.google.cloud.bigquery.TableResult;
import com.google.cloud.pso.bq_pii_classifier.entities.NonRetryableApplicationException;
import com.google.cloud.pso.bq_pii_classifier.entities.PolicyTagInfo;
import com.google.cloud.pso.bq_pii_classifier.entities.TablePolicyTags;
import com.google.cloud.pso.bq_pii_classifier.entities.TableSpec;
import com.google.cloud.pso.bq_pii_classifier.helpers.Utils;
import com.google.cloud.pso.bq_pii_classifier.services.bq.BigQueryService;
import com.google.common.io.Resources;

import java.io.IOException;
import java.net.URL;
import java.nio.charset.StandardCharsets;
import java.util.HashMap;
import java.util.Map;

public class FindingsReaderStandardDlp implements FindingsReader {

    private BigQueryService bqService;
    private String dlpProject;
    private String sqlTemplatePath;

    public FindingsReaderStandardDlp(BigQueryService bqService, String dlpProject, String dlpDataset, String dlpTable, String datasetDomainMapView, String projectDomainMapView, String infoTypesPolicyTagsMapView, String sqlTemplatePath) {
        this.bqService = bqService;
        this.dlpProject = dlpProject;
        this.dlpDataset = dlpDataset;
        this.dlpTable = dlpTable;
        this.datasetDomainMapView = datasetDomainMapView;
        this.projectDomainMapView = projectDomainMapView;
        this.infoTypesPolicyTagsMapView = infoTypesPolicyTagsMapView;
        this.sqlTemplatePath = sqlTemplatePath;
    }

    private String dlpDataset;
    private String dlpTable;
    private String datasetDomainMapView;
    private String projectDomainMapView;
    private String infoTypesPolicyTagsMapView;

    private String generateQuery(String dlpJobName) throws IOException {

        final URL url = Resources.getResource(sqlTemplatePath);

        String queryTemplate = Resources.toString(url, StandardCharsets.UTF_8);

        /*
        Since we have N taxonomies in N regions we need the table location in order to look up the correct set of
        policy tags.
        To avoid an API call to fetch the table location we extract the location info from the DLP job id given that
        we run the dlp job in the same region as the table
         */
        String region = Utils.extractDLPRegionFromJobNameToBQRegion(dlpJobName);

        return queryTemplate.replace("${project}", dlpProject)
                .replace("${dataset}", dlpDataset)
                .replace("${config_view_infotypes_policytags_map}", infoTypesPolicyTagsMapView)
                .replace("${config_view_dataset_domain_map}", datasetDomainMapView)
                .replace("${config_view_project_domain_map}", projectDomainMapView)
                .replace("${results_table}", dlpTable)
                .replace("${param_lookup_key}", dlpJobName)
                .replace("${param_region}", region);
    }

    /**
     * Look for DLP results by a tableSpec. Returns a map of fields to policy tags or null if DLP
     * doesn't have findings
     *
     * @param dlpJobName: "projects/<PROJECT>/locations/<GCP REGION>/dlpJobs/<JOB ID>"
     * @return
     * @throws InterruptedException
     * @throws NonRetryableApplicationException
     * @throws IOException
     */
    public TablePolicyTags getFieldsToPolicyTagsMap(String dlpJobName) throws InterruptedException, NonRetryableApplicationException, IOException {

        String formattedQuery = generateQuery(dlpJobName);

        // Create a job ID so that we can safely retry.
        Job queryJob = bqService.submitJob(formattedQuery);

        TableResult result = bqService.waitAndGetJobResults(queryJob);

        // Construct a mapping between field names and DLP infotypes
        Map<String, PolicyTagInfo> fieldsToPolicyTagMap = new HashMap<>();
        String tableSpecStr = "";
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
            String infoType = row.get("info_type").getStringValue();

            if (row.get("policy_tag").isNull()) {
                throw new NonRetryableApplicationException(
                        String.format(
                                "getFieldsToPolicyTagsMap query returned rows with null policy_tag for column '%s' of info_type '%s'. Checkout the classification taxonomy configuration and the DLP inspection template. All InfoTypes defined in the inspection template must have corresponding entries in the classification taxonomies.",
                                column_name, infoType));
            }
            String policyTag = row.get("policy_tag").getStringValue();

            if (row.get("classification").isNull()) {
                throw new NonRetryableApplicationException(
                        String.format(
                                "getFieldsToPolicyTagsMap query returned rows with null classification for column '%s' of info_type '%s'. Checkout the classification taxonomy configuration and the DLP inspection template. All InfoTypes defined in the inspection template must have corresponding entries in the classification taxonomies.",
                                column_name, infoType));
            }
            String classification = row.get("classification").getStringValue();

            if (row.get("table_spec").isNull()) {
                throw new NonRetryableApplicationException("getFieldsToPolicyTagsMap query returned rows with null table_spec");
            }
            tableSpecStr = row.get("table_spec").getStringValue();

            fieldsToPolicyTagMap.put(column_name, new PolicyTagInfo(infoType, policyTag, classification));
        }

        if (fieldsToPolicyTagMap.isEmpty())
            return null;
        else
            return new TablePolicyTags(TableSpec.fromSqlString(tableSpecStr), fieldsToPolicyTagMap);
    }
}
