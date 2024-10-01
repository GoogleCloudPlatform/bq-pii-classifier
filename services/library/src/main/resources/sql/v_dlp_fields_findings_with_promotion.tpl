  WITH config AS
    (
       SELECT * FROM `${project}.${dataset}.${config_view_infotypes_policytags_map}`
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
    )
    , projects_domains AS
    (
        SELECT * FROM `${project}.${dataset}.${config_view_project_domain_map}`
    )
    , dlp_results_core AS
    (
        -- get the latest DLP scan results for a table
    SELECT
    job_name AS dlp_job_name,
    l.record_location.record_key.big_query_key.table_reference.project_id AS project_id,
    l.record_location.record_key.big_query_key.table_reference.dataset_id AS dataset_id,
    l.record_location.record_key.big_query_key.table_reference.table_id AS table_id,
    l.record_location.field_id.name AS field_name,
    o.info_type.name AS info_type,
    o.likelihood,
    COUNT(1) AS findings
    FROM `${project}.${dataset}.${results_table}` o
    , UNNEST(location.content_locations) l

        -- job_name filter is not pushed when we use it in the outer query
    WHERE job_name  = '${param_lookup_key}'
    GROUP BY 1,2,3,4,5,6,7


    )
    , dlp_results AS
    (
    -- keep this in a WITH view to facilitate unit testing by creating static input
    SELECT DISTINCT
        dlp_job_name,
        CONCAT(project_id, ".", dataset_id, ".", table_id) AS table_spec,
        project_id,
        dataset_id,
        table_id,
        -- DLP reports column names for nested repeated records with the array index of the finding.
        -- normalize the column names for nested repeated records by removing the '[index]' part and selecting distinct
        -- e.g. hits[0].referer, hits[1].referer, etc becomes hits.referer
        REGEXP_REPLACE(field_name, r"(\[\d+\]\.)", '.') AS field_name,
        info_type,
        likelihood,
        findings
    FROM dlp_results_core

    )

    , info_type_scores AS
        (
        SELECT
        o.dlp_job_name,
        o.table_spec,
        o.project_id,
        o.dataset_id,
        o.field_name,
        o.info_type,
        o.likelihood,
        o.findings,
        lh.likelihood_rank,
        # Calculate a score for each field/info_type/likelihood finding
        lh.likelihood_rank * o.findings AS info_type_weight
        FROM `dlp_results` o
        INNER JOIN likelihood lh ON o.likelihood = lh.likelihood
        GROUP BY 1,2,3,4,5,6,7,8,9
        )
        , merge_same_info_type_scores AS
        (
            # some fields will have same infotype finidings with different likelihood. We need to add up their scores
            # For example, for FAX_NUMBER 3 row will have PHONE/Likely and 10 rows Phone/Highly Likely.
            SELECT
                o.dlp_job_name,
                o.table_spec,
                o.project_id,
                o.dataset_id,
                o.field_name,
                o.info_type,
                MAX(likelihood_rank) AS max_likelihood_rank,
                -- merge scores for similar field/info_type regardless of likelihood
                SUM(o.info_type_weight) AS info_type_weight,
                -- rank the field/info_type by the merged score
                -- field/info_type with the same score will have the same rank. In the next step we detect those and mark them "MIXED_PII"
                RANK() OVER(PARTITION BY o.table_spec, o.field_name ORDER BY SUM(o.info_type_weight) DESC) AS info_type_weight_rank
            FROM  info_type_scores o
            GROUP BY 1,2,3,4,5,6
        )

        , fields_with_mixed_pii AS
        (

            SELECT
            table_spec,
            field_name,
            COUNT(1) AS ties
            FROM  merge_same_info_type_scores
            WHERE info_type_weight_rank = 1
            GROUP BY 1,2
            HAVING COUNT(1) > 1
        ),
        final_info_type AS
        (
            SELECT DISTINCT
                s.dlp_job_name,
                s.table_spec,
                s.project_id,
                s.dataset_id,
                s.field_name,
                CASE WHEN m.field_name IS NULL THEN s.info_type ELSE "MIXED" END AS info_type,
                -- If we find more than one info type then we are reporting MIXED with the highest likelihood. Else we use the info type's max detected likelihood
                CASE WHEN m.field_name IS NULL THEN l.likelihood ELSE "VERY_LIKELY" END AS max_likelihood
            FROM merge_same_info_type_scores AS s
            LEFT JOIN fields_with_mixed_pii AS m ON s.table_spec = m.table_spec AND s.field_name = m.field_name
            LEFT JOIN likelihood l ON s.max_likelihood_rank = l.likelihood_rank
            WHERE s.info_type_weight_rank = 1
        )
        , with_policy_tags AS
        (
            SELECT
                i.dlp_job_name,
                i.table_spec,
                i.project_id,
                i.dataset_id,
                i.field_name,
                i.info_type,
                c.policy_tag,
                c.classification,
                i.max_likelihood
            FROM final_info_type i
            LEFT JOIN datasets_domains dd ON dd.project = i.project_id AND dd.dataset = i.dataset_id
            LEFT JOIN projects_domains pd ON pd.project = i.project_id
             -- get tag ids that belong to certain domain. Use dataset-level domain if found, else project-level domain
            LEFT JOIN config c ON c.domain = COALESCE(dd.domain , pd.domain ) AND c.info_type = i.info_type AND c.region = '${param_region}'
        )

        SELECT table_spec, field_name, info_type, policy_tag, classification FROM with_policy_tags WHERE info_type IS NOT NULL























