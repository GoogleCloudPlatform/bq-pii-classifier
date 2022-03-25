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
    , likelihood AS
    (
        SELECT 'VERY_UNLIKELY' AS likelihood, 1 AS likelihood_rank UNION ALL
        SELECT 'UNLIKELY' AS likelihood, 2 AS likelihood_rank UNION ALL
        SELECT 'POSSIBLE' AS likelihood, 3 AS likelihood_rank UNION ALL
        SELECT 'LIKELY' AS likelihood, 4 AS likelihood_rank UNION ALL
        SELECT 'VERY_LIKELY' AS likelihood, 5 AS likelihood_rank
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
    , dlp_results_with_rank AS
    (
        -- get the latest DLP scan results for a table
    SELECT
    l.record_location.record_key.big_query_key.table_reference.project_id AS project_id,
    l.record_location.record_key.big_query_key.table_reference.dataset_id AS dataset_id,
    l.record_location.record_key.big_query_key.table_reference.table_id AS table_id,
    l.record_location.field_id.name AS field_name,
    o.info_type.name AS info_type,
    o.likelihood,
    -- order by the job_name since it has the runId which is a timestamp
    RANK() OVER (PARTITION BY location.container.full_path ORDER BY o.job_name DESC) AS rank
    FROM `${results_table_spec}` o
    , UNNEST(location.content_locations) l

    )
    , dlp_results AS
    (
    -- keep this in a WITH view to facilitate unit testing by creating static input
    SELECT DISTINCT
        CONCAT(d.project_id, ".", d.dataset_id, ".", d.table_id) AS table_spec,
        d.project_id,
        d.dataset_id,
        d.table_id,
        -- DLP reports column names for nested repeated records with the array index of the finding.
        -- normalize the column names for nested repeated records by removing the '[index]' part and selecting distinct
        -- e.g. hits[0].referer, hits[1].referer, etc becomes hits.referer
        REGEXP_REPLACE(d.field_name, r"(\[\d+\]\.)", '.') AS field_name,
        d.info_type,
        d.likelihood,
        lh.likelihood_rank
    FROM dlp_results_with_rank d
    INNER JOIN likelihood lh ON d.likelihood = lh.likelihood
    WHERE rank = 1
    )

    , info_types_per_field AS (
      SELECT
        o.table_spec,
        o.project_id,
        o.dataset_id,
        o.field_name,
        ARRAY_AGG (DISTINCT o.info_type) AS info_types,
        MAX(o.likelihood_rank) AS max_likelihood_rank
      FROM`dlp_results` o
      GROUP BY
        o.table_spec,
        o.project_id,
        o.dataset_id,
        o.field_name
         )

        , one_info_type_per_field AS (
            SELECT
             i.table_spec,
             i.project_id,
             i.dataset_id,
             i.field_name,
             -- If the field has more than one INFO_TYPE detected, use special info_type MIXED
             CASE WHEN ARRAY_LENGTH(i.info_types) > 1 THEN 'MIXED' ELSE i.info_types[OFFSET(0)] END AS info_type,
             -- If we find more than one info type then we are reporting MIXED with the highest likelihood. Else we use the info type's max detected likelihood
             CASE WHEN ARRAY_LENGTH(i.info_types) > 1 THEN 'VERY_LIKELY' ELSE lh.likelihood END AS max_likelihood
            FROM info_types_per_field i
            INNER JOIN likelihood lh ON i.max_likelihood_rank = lh.likelihood_rank
        )

      , info_type_with_policy_tags AS (
      SELECT
        o.table_spec,
        o.project_id,
        o.dataset_id,
        o.field_name,
        o.info_type,
        c.policy_tag,
        o.max_likelihood
      FROM
        `one_info_type_per_field` o
      LEFT JOIN datasets_domains dd ON dd.project = o.project_id AND dd.dataset = o.dataset_id
      LEFT JOIN projects_domains pd ON pd.project = o.project_id
        -- get tag ids that belong to certain domain. Use dataset-level domain if found, else project-level domain
      LEFT JOIN config c ON c.domain = COALESCE(dd.domain, pd.domain ) AND c.info_type = o.info_type
      GROUP BY 1, 2,3,4,5,6,7
      )

      SELECT * FROM info_type_with_policy_tags