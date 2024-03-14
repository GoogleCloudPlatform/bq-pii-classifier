    WITH config AS
    (
    -- keep this in a WITH view to facilitate unit testing by creating static input
       SELECT * FROM `${project}.${dataset}.${config_view_infotypes_policytags_map}`

    #  SELECT 'dm1' AS domain, 'EMAIL_ADDRESS' AS info_type, 'd1_email_policy_tag' AS policy_tag UNION ALL
    #  SELECT 'dm1' AS domain, 'PERSON_NAME' AS info_type, 'd1_person_policy_tag' AS policy_tag UNION ALL
    #  SELECT 'dm1' AS domain, 'STREET_ADDRESS' AS info_type, 'd1_street_address_policy_tag' AS policy_tag UNION ALL
    #  SELECT 'dm2' AS domain, 'EMAIL_ADDRESS' AS info_type, 'd2_email_policy_tag' AS policy_tag UNION ALL
    #  SELECT 'dm2' AS domain, 'PERSON_NAME' AS info_type, 'd2_person_policy_tag' AS policy_tag UNION ALL
    #  SELECT 'dm2' AS domain, 'STREET_ADDRESS' AS info_type, 'd2_street_address_policy_tag' AS policy_tag
    )
    , datasets_domains AS
    (
        SELECT * FROM `${project}.${dataset}.${config_view_dataset_domain_map}`
        # SELECT 'p1' AS project, 'ds1' AS dataset, 'dm1' AS domain UNION ALL
        # SELECT 'p1' AS project, 'ds2' AS dataset, 'dm2' AS domain
    )
    , projects_domains AS
    (
        SELECT * FROM `${project}.${dataset}.${config_view_project_domain_map}`
        # SELECT 'p1' AS project, 'dm1' AS domain UNION ALL
        # SELECT 'p1' AS project, 'dm2' AS domain
    )
    , column_info_type_base AS
        (

        SELECT
        column_profile.dataset_project_id,
        column_profile.dataset_id,
        column_profile.table_id,
        column_profile.column AS column_name,
        CASE
           -- If Auto DLP promotes only one PII type, use this PII
           WHEN column_profile.column_info_type.info_type.name IS NOT NULL THEN column_profile.column_info_type.info_type.name
           -- If Auto DLP doesn't promote a PII type but finds only one "Other PII" type, use that one other PII type
           WHEN column_profile.column_info_type.info_type.name IS NULL AND ARRAY_LENGTH(column_profile.other_matches) = 1 THEN column_profile.other_matches[ORDINAL (1)].info_type.name
           -- If Auto DLP doesn't promote a PII type but finds more than one "Other PII" type, use MIXED
            WHEN column_profile.column_info_type.info_type.name IS NULL AND ARRAY_LENGTH(column_profile.other_matches) > 1 THEN "MIXED" END AS final_info_type,
        FROM `${project}.${dataset}.${results_table}`
        WHERE (column_profile.column_info_type.info_type.name IS NOT NULL OR column_profile.other_matches IS NOT NULL)

        AND CONCAT(column_profile.dataset_project_id, '.', column_profile.dataset_id, '.', column_profile.table_id) = '${param_lookup_key}'
        )

        SELECT DISTINCT
        -- DLP reports column names for nested repeated records with the array index of the finding.
        -- normalize the column names for nested repeated records by removing the '[index]' part and selecting distinct
        -- e.g. hits[0].referer, hits[1].referer, etc becomes hits.referer
        REGEXP_REPLACE(o.column_name, r"(\[\d+\]\.)", '.') AS field_name,
        o.final_info_type AS info_type,
        c.policy_tag,
        c.classification
        FROM column_info_type_base o
        LEFT JOIN datasets_domains dd ON dd.project = o.dataset_project_id AND dd.dataset = o.dataset_id
        LEFT JOIN projects_domains pd ON pd.project = o.dataset_project_id
        -- get tag ids that belong to certain domain. Use dataset-level domain if found, else project-level domain
        LEFT JOIN config c ON c.domain = COALESCE(dd.domain , pd.domain ) AND c.info_type = o.final_info_type
        WHERE o.final_info_type IS NOT NULL
        ORDER BY 1,2
