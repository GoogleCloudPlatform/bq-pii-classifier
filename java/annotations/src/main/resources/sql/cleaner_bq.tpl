INSERT INTO `${project}.${logging_dataset}.${dispatcher_runs_table}`

WITH a AS (

        SELECT
            CASE WHEN SPLIT(c.table_profile.name, "/")[OFFSET(3)] = "europe" THEN "eu" ELSE SPLIT(c.table_profile.name, "/")[OFFSET(3)] END AS table_region,
            CAST(c.table_profile.config_snapshot.data_profile_job.location.folder_id AS STRING) AS folder_id,
            c.table_profile.dataset_project_id AS project_id,
            c.table_profile.dataset_id AS dataset_id,
            c.table_profile.table_id AS table_id,
            t.value AS tag_value
        FROM `${project}.${dlp_dataset}.${results_table}` c, UNNEST(c.table_profile.tags) t
        WHERE
               (REGEXP_CONTAINS(CAST(t.table_profile.config_snapshot.data_profile_job.location.folder_id AS STRING), r'${folder_id_regex}') OR t.table_profile.config_snapshot.data_profile_job.location.folder_id IS NULL)
               AND REGEXP_CONTAINS(c.table_profile.dataset_project_id, r'${project_id_regex}')
               AND REGEXP_CONTAINS(c.table_profile.dataset_id, r'${dataset_id_regex}')
               AND REGEXP_CONTAINS(c.table_profile.table_id, r'${table_id_regex}')
               AND (
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
    a.dataset_id,
    a.table_id,
    a.table_region,
    a.tag_value,
FROM a
-- This dummy cross join is used to generate multiples of the dataset for stress testing. Default is 1.
CROSS JOIN UNNEST(GENERATE_ARRAY(1, ${rows_multiplication_factor})) AS dummy_row;

SELECT * FROM `${project}.${logging_dataset}.${dispatcher_runs_table}` WHERE run_id = '${run_id}';