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
    , ranked_profiles AS (

        SELECT
        column_profile.dataset_project_id,
        column_profile.dataset_id,
        column_profile.table_id,
        column_profile.column AS column_name,
        column_profile.column_info_type.info_type.name AS dlp_info_type,
        column_profile.other_matches AS dlp_other_matches,
        RANK() OVER (PARTITION BY CONCAT(column_profile.dataset_project_id, '.', column_profile.dataset_id, '.', column_profile.table_id)  ORDER BY column_profile.profile_last_generated.timestamp DESC) AS column_profile_rank
        FROM `${project}.${dataset}.${results_table}`
        WHERE (column_profile.column_info_type.info_type.name IS NOT NULL OR column_profile.other_matches IS NOT NULL)
        AND CONCAT(column_profile.dataset_project_id, '.', column_profile.dataset_id, '.', column_profile.table_id) = '${param_lookup_key}'

   ), latest_profiles AS (

        SELECT
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
        FROM ranked_profiles
        WHERE column_profile_rank = 1
)


      SELECT
        -- DLP reports column names for nested repeated records with the array index of the finding.
        -- normalize the column names for nested repeated records by removing the '[index]' part and selecting distinct
        -- e.g. hits[0].referer, hits[1].referer, etc becomes hits.referer
        REGEXP_REPLACE(o.column_name, r"(\[\d+\]\.)", '.') AS field_name,
        o.final_info_type AS info_type,
        c.policy_tag
        FROM latest_profiles o
        LEFT JOIN datasets_domains dd ON dd.project = o.dataset_project_id AND dd.dataset = o.dataset_id
        LEFT JOIN projects_domains pd ON pd.project = o.dataset_project_id
        -- get tag ids that belong to certain domain. Use dataset-level domain if found, else project-level domain
        LEFT JOIN config c ON c.domain = COALESCE(dd.domain , pd.domain ) AND c.info_type = o.final_info_type
        WHERE o.final_info_type IS NOT NULL
        ORDER BY 1,2
