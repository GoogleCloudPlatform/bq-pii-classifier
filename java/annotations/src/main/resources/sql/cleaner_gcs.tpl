INSERT INTO `${project}.${logging_dataset}.${dispatcher_runs_table}`

WITH a AS (
    SELECT
        CAST(file_store_profile.config_snapshot.discovery_config.org_config.location.folder_id AS STRING) AS folder_id,
        r.file_store_profile.project_id AS project_id,
        SUBSTRING(r.file_store_profile.file_store_path,6) AS bucket_name,
        r.file_store_profile.file_store_location AS bucket_location,
        t.value AS tag_value
    FROM `${project}.${dlp_dataset}.${dlp_gcs_results_table}` r, UNNEST(r.file_store_profile.tags) t
    WHERE
            REGEXP_CONTAINS(file_store_profile.project_id, r'${project_name_regex}') AND
            REGEXP_CONTAINS(SUBSTRING(file_store_profile.file_store_path,6), r'${bucket_name_regex}') AND
            (REGEXP_CONTAINS(CAST(file_store_profile.config_snapshot.discovery_config.org_config.location.folder_id AS STRING), r'${folder_id_regex}') OR file_store_profile.config_snapshot.discovery_config.org_config.location.folder_id IS NULL) AND
            (
              t.value = '${dlp_sensitivity_level_tag_value_high}' OR
              t.value = '${dlp_sensitivity_level_tag_value_moderate}' OR
              t.value = '${dlp_sensitivity_level_tag_value_low}'
            )
)

SELECT
    '${run_id}' AS run_id,
    CONCAT('${run_id}', '-', GENERATE_UUID()) AS tracking_id,
    a.folder_id,
    a.project_id,
    a.bucket_name,
    a.bucket_location,
    a.tag_value,
FROM a
-- This dummy cross join is used to generate multiples of the dataset for stress testing. Default is 1.
CROSS JOIN UNNEST(GENERATE_ARRAY(1, ${rows_multiplication_factor})) AS dummy_row;

SELECT * FROM `${project}.${logging_dataset}.${dispatcher_runs_table}` WHERE run_id = '${run_id}';