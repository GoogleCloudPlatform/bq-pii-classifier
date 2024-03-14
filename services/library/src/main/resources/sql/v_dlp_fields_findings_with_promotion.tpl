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
    o.likelihood
    FROM `${project}.${dataset}.${results_table}` o
    , UNNEST(location.content_locations) l

    -- job_name filter is not pushed when we use it in the outer query
    WHERE job_name  = '${param_lookup_key}'


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
        likelihood
    FROM dlp_results_core


            -- test one field, one likelihood
    # SELECT 'field1' AS field_name, 'EMAIL_ADDRESS' AS info_type, 'LIKELY' AS likelihood, 'p1' AS project_id, 'ds1' AS dataset_id, 'p1.ds1.t1' AS table_spec  UNION ALL
    # SELECT 'field1' AS field_name, 'PERSON_NAME' AS info_type, 'LIKELY' AS likelihood, 'p1' AS project_id, 'ds1' AS dataset_id, 'p1.ds1.t1' AS table_spec UNION ALL
    # -- test one field, diff likelihood
    # SELECT 'field2' AS field_name, 'EMAIL_ADDRESS' AS info_type, 'LIKELY' AS likelihood, 'p1' AS project_id, 'ds1' AS dataset_id, 'p1.ds1.t1' AS table_spec UNION ALL
    # SELECT 'field2' AS field_name, 'PERSON_NAME' AS info_type, 'VERY_LIKELY' AS likelihood, 'p1' AS project_id, 'ds1' AS dataset_id, 'p1.ds1.t1' AS table_spec UNION ALL
    # -- test one field
    # SELECT 'field3' AS field_name, 'EMAIL_ADDRESS' AS info_type, 'POSSIBLE' AS likelihood, 'p1' AS project_id, 'ds1' AS dataset_id, 'p1.ds1.t1' AS table_spec UNION ALL
    # -- test one field, one likelyhood, different count of findings
    # SELECT 'field4' AS field_name, 'STREET_ADDRESS' AS info_type, 'LIKELY' AS likelihood, 'p1' AS project_id, 'ds1' AS dataset_id, 'p1.ds1.t1' AS table_spec UNION ALL
    # SELECT 'field4' AS field_name, 'STREET_ADDRESS' AS info_type, 'LIKELY' AS likelihood, 'p1' AS project_id, 'ds1' AS dataset_id, 'p1.ds1.t1' AS table_spec UNION ALL
    # SELECT 'field4' AS field_name, 'PERSON_NAME' AS info_type, 'LIKELY' AS likelihood, 'p1' AS project_id, 'ds1' AS dataset_id, 'p1.ds1.t1' AS table_spec


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
        lh.likelihood_rank,
        COUNT(1) findings,
        # Calculate a score for each field/info_type/likelihood finding
        lh.likelihood_rank * COUNT(1) AS info_type_weight
        FROM `dlp_results` o
        INNER JOIN likelihood lh ON o.likelihood = lh.likelihood
        GROUP BY 1,2,3,4,5,6,7,8

        -- -- Unit tests
        -- -- Normal case
        -- SELECT 'p1.ds1.t1' AS table_spec, 'first_name' AS field_name, 'PERSON_NAME' AS info_type, 5 AS likelihood_rank, 10 AS findings, 5*10 AS info_type_weight, 'p1' AS project_id, 'ds1' AS dataset_id
        -- UNION ALL
        -- SELECT 'p1.ds1.t1' AS table_spec, 'first_name' AS field_name, 'EMAIL_ADDRESS' AS info_type, 2 AS likelihood_rank, 1 AS findings, 2*1 AS info_type_weight, 'p1' AS project_id, 'ds1' AS dataset_id
        -- UNION ALL
        -- -- Merging case
        -- SELECT 'p1.ds1.t1' AS table_spec, 'email' AS field_name, 'EMAIL_ADDRESS' AS info_type, 5 AS likelihood_rank, 10 AS findings, 5*10 AS info_type_weight, 'p1' AS project_id, 'ds1' AS dataset_id
        -- UNION ALL
        -- SELECT 'p1.ds1.t1' AS table_spec, 'email' AS field_name, 'EMAIL_ADDRESS' AS info_type, 4 AS likelihood_rank, 2 AS findings, 4*2 AS info_type_weight, 'p1' AS project_id, 'ds1' AS dataset_id
        -- UNION ALL
        -- -- Tie score case
        -- SELECT 'p1.ds1.t1' AS table_spec, 'street' AS field_name, 'STREET_ADDRESS' AS info_type, 3 AS likelihood_rank, 4 AS findings, 3*4 AS info_type_weight, 'p1' AS project_id, 'ds1' AS dataset_id
        -- UNION ALL
        -- SELECT 'p1.ds1.t1' AS table_spec, 'street' AS field_name, 'PERSON_NAME' AS info_type, 2 AS likelihood_rank, 6 AS findings, 2*6 AS info_type_weight, 'p1' AS project_id, 'ds1' AS dataset_id

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
            LEFT JOIN config c ON c.domain = COALESCE(dd.domain , pd.domain ) AND c.info_type = i.info_type
        )

        SELECT table_spec, field_name, info_type, policy_tag, classification FROM with_policy_tags WHERE info_type IS NOT NULL











