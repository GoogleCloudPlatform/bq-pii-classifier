INSERT INTO `${project}.${logging_dataset}.${dispatcher_runs_table}`

WITH  core AS (

        SELECT
        CASE WHEN SPLIT(c.column_profile.name, "/")[OFFSET(3)] = "europe" THEN "eu" ELSE SPLIT(c.column_profile.name, "/")[OFFSET(3)] END AS table_region,
        CAST(t.table_profile.config_snapshot.data_profile_job.location.folder_id AS STRING) AS folder_id,
        c.column_profile.dataset_project_id,
        c.column_profile.dataset_id,
        c.column_profile.table_id,
        c.column_profile.column AS column_name,
        c.column_profile.column_info_type.info_type.name AS dlp_info_type_name,
        ARRAY_AGG(STRUCT(other_matches.info_type.name AS info_type_name, CAST(other_matches.estimated_prevalence AS INT64) AS info_type_prevalence) ORDER BY other_matches.estimated_prevalence DESC) AS dlp_other_matches
        FROM `${project}.${dlp_dataset}.${results_table}` c, UNNEST(c.column_profile.other_matches) other_matches
        INNER JOIN `${project}.${dlp_dataset}.${results_table}` t ON c.column_profile.table_data_profile = t.table_profile.name
        WHERE (c.column_profile.column_info_type.info_type.name IS NOT NULL OR c.column_profile.other_matches IS NOT NULL)
               AND REGEXP_CONTAINS(CAST(t.table_profile.config_snapshot.data_profile_job.location.folder_id AS STRING), r'${folder_id_regex}')
               AND REGEXP_CONTAINS(c.column_profile.dataset_project_id, r'${project_id_regex}')
               AND REGEXP_CONTAINS(c.column_profile.dataset_id, r'${dataset_id_regex}')
               AND REGEXP_CONTAINS(c.column_profile.table_id, r'${table_id_regex}')
        GROUP BY 1,2,3,4,5,6,7


   )

      SELECT
        '${run_id}' AS run_id,
        CONCAT('${run_id}', '-', GENERATE_UUID()) AS tracking_id,
        folder_id,
        dataset_project_id AS project_id,
        dataset_id AS dataset_id,
        table_id AS table_id,
        -- DLP reports column names for nested repeated records with the array index of the finding.
        -- normalize the column names for nested repeated records by removing the '[index]' part and selecting distinct
        -- e.g. hits[0].referer, hits[1].referer, etc becomes hits.referer
        ARRAY_AGG(STRUCT(
            REGEXP_REPLACE(column_name, r"(\[\d+\]\.)", '.') AS field_name,
            dlp_info_type_name,
            dlp_other_matches
        )) AS fields
        FROM core
        GROUP BY
        run_id,
        folder_id,
        dataset_project_id,
        dataset_id,
        table_id ;

SELECT * FROM `${project}.${logging_dataset}.${dispatcher_runs_table}` WHERE run_id = '${run_id}';
