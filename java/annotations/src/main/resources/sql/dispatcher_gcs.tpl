INSERT INTO `${project}.${logging_dataset}.${dispatcher_runs_table}`

WITH a AS (
    SELECT
        file_store_profile.name AS profile_name,
        SUBSTRING(file_store_profile.file_store_path,6) AS bucket_name,
        file_store_profile.project_id AS project_id,
        CAST(file_store_profile.config_snapshot.discovery_config.org_config.location.folder_id AS STRING) AS folder_id,
        ARRAY_TO_STRING(ARRAY_AGG(DISTINCT ss.info_type.name), ',') AS info_types
    FROM `${project}.${dlp_dataset}.${dlp_gcs_results_table}`,
        UNNEST(file_store_profile.file_cluster_summaries) s,
        UNNEST(s.file_store_info_type_summaries) ss
    WHERE
        REGEXP_CONTAINS(file_store_profile.project_id, r'${project_name_regex}') AND
        REGEXP_CONTAINS(SUBSTRING(file_store_profile.file_store_path,6), r'${bucket_name_regex}') AND
        REGEXP_CONTAINS(CAST(file_store_profile.config_snapshot.discovery_config.org_config.location.folder_id AS STRING), r'${folder_id_regex}')
    GROUP BY 1,2,3,4
    HAVING
        ARRAY_LENGTH(ARRAY_AGG(DISTINCT ss.info_type.name)) > 0
)

SELECT
    '${run_id}' AS run_id,
    CONCAT('${run_id}', '-', GENERATE_UUID()) AS tracking_id,
    a.profile_name,
    a.bucket_name,
    a.project_id,
    a.folder_id,
    a.info_types
FROM a
-- This dummy cross join is used to generate multiples of the dataset for stress testing. Default is 1.
CROSS JOIN UNNEST(GENERATE_ARRAY(1, ${rows_multiplication_factor})) AS dummy_row;

SELECT * FROM `${project}.${logging_dataset}.${dispatcher_runs_table}` WHERE run_id = '${run_id}';