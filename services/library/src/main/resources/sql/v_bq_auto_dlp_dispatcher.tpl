INSERT INTO `${project}.${dataset}.${dispatcher_runs_table}`
     WITH config AS
    (
       SELECT * FROM `${project}.${dataset}.${config_view_infotypes_policytags_map}`
    )
    , datasets_domains AS
    (
        SELECT * FROM `${project}.${dataset}.${config_view_dataset_domain_map}`
    )
    , projects_domains AS
    (
        SELECT * FROM `${project}.${dataset}.${config_view_project_domain_map}`
    )
    , core AS (

        SELECT
        CASE WHEN SPLIT(column_profile.name, "/")[OFFSET(3)] = "europe" THEN "eu" ELSE SPLIT(column_profile.name, "/")[OFFSET(3)] END AS table_region,
        column_profile.dataset_project_id,
        column_profile.dataset_id,
        column_profile.table_id,
        column_profile.column AS column_name,
        column_profile.column_info_type.info_type.name AS dlp_info_type,
        column_profile.other_matches AS dlp_other_matches
        FROM `${project}.${dataset}.${results_table}`
        WHERE (column_profile.column_info_type.info_type.name IS NOT NULL OR column_profile.other_matches IS NOT NULL)
               AND REGEXP_CONTAINS(column_profile.dataset_project_id, r'${project_id_regex}')
               AND REGEXP_CONTAINS(column_profile.dataset_id, r'${dataset_id_regex}')
               AND REGEXP_CONTAINS(column_profile.table_id, r'${table_id_regex}')

   ), final_pii_type AS (

        SELECT
        table_region,
        dataset_project_id,
        dataset_id,
        table_id,
        column_name,
        CASE
           -- If Auto DLP promotes only one PII type, use this PII
           WHEN dlp_info_type IS NOT NULL THEN dlp_info_type
           -- If Auto DLP doesn't promote a PII type but finds only one "Other PII" type, use that one other PII type
           WHEN dlp_info_type IS NULL AND ARRAY_LENGTH(dlp_other_matches) = 1 THEN dlp_other_matches[ORDINAL (1)].info_type.name
           -- If Auto DLP doesn't promote a PII type but finds more than one "Other PII" type, use MIXED
            WHEN dlp_info_type IS NULL AND ARRAY_LENGTH(dlp_other_matches) > 1 THEN "MIXED" END AS final_info_type,
        FROM core
)

      SELECT
        '${run_id}' AS run_id,
        CONCAT('${run_id}', '-', GENERATE_UUID()) AS tracking_id,
        dataset_project_id AS project_id,
        dataset_id AS dataset_id,
        table_id AS table_id,
        -- DLP reports column names for nested repeated records with the array index of the finding.
        -- normalize the column names for nested repeated records by removing the '[index]' part and selecting distinct
        -- e.g. hits[0].referer, hits[1].referer, etc becomes hits.referer
        ARRAY_AGG(
        STRUCT(
        REGEXP_REPLACE(l.column_name, r"(\[\d+\]\.)", '.') AS field_name,
        l.final_info_type AS info_type,
        c.policy_tag,
        c.classification)
        ) AS fields
        FROM final_pii_type l
        LEFT JOIN datasets_domains dd ON dd.project = l.dataset_project_id AND dd.dataset = l.dataset_id
        LEFT JOIN projects_domains pd ON pd.project = l.dataset_project_id
        -- get tag ids that belong to certain domain. Use dataset-level domain if found, else project-level domain
        LEFT JOIN config c ON c.domain = COALESCE(dd.domain , pd.domain, '${default_domain_name}') AND c.info_type = l.final_info_type AND c.region = l.table_region
        WHERE l.final_info_type IS NOT NULL
        GROUP BY 1,2,3,4,5;

SELECT * FROM `${project}.${dataset}.${dispatcher_runs_table}` WHERE run_id = '${run_id}';