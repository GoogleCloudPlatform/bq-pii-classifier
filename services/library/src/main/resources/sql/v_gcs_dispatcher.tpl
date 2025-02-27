INSERT INTO `${project}.${dataset}.${dispatcher_runs_table}`

WITH a AS (
    SELECT
        SUBSTRING(file_store_profile.file_store_path,6) AS bucket_name,
        file_store_profile.project_id AS project_id,
        ARRAY_TO_STRING(ARRAY_AGG(DISTINCT ss.info_type.name), ',') AS info_types
    FROM `${project}.${dataset}.${dlp_gcs_results_table}`,
        UNNEST(file_store_profile.file_cluster_summaries) s,
        UNNEST(s.file_store_info_type_summaries) ss
    WHERE
        REGEXP_CONTAINS(file_store_profile.project_id, r'${project_name_regex}') AND
        REGEXP_CONTAINS(SUBSTRING(file_store_profile.file_store_path,6), r'${bucket_name_regex}')
    GROUP BY 1,2
    HAVING
        ARRAY_LENGTH(ARRAY_AGG(DISTINCT ss.info_type.name)) > 0
)

SELECT
    '${run_id}' AS run_id,
    CONCAT('${run_id}', '-', GENERATE_UUID()) AS tracking_id,
    a.bucket_name,
    a.project_id,
    a.info_types
FROM a
CROSS JOIN (SELECT num AS number FROM UNNEST(GENERATE_ARRAY(1, 10000)) AS num) AS s
LIMIT 100000000;

SELECT * FROM `${project}.${dataset}.${dispatcher_runs_table}` WHERE run_id = '${run_id}';