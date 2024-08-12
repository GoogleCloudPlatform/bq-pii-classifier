SELECT
TIMESTAMP_MILLIS(CAST(SUBSTR(jsonPayload.global_run_id, 0, 13) AS INT64)) AS start_time,
jsonPayload.global_run_id AS run_id,
jsonPayload.global_tracker AS tracker,
jsonPayload.tag_history_log_project_id AS project_id,
jsonPayload.tag_history_log_dataset_id AS dataset_id,
jsonPayload.tag_history_log_table_id AS table_id,
jsonPayload.tag_history_log_field_name AS field_id,
jsonPayload.tag_history_log_existing_policy_tag_id AS existing_policy_tag,
jsonPayload.tag_history_log_new_policy_tag_id AS new_policy_tag,
jsonPayload.tag_history_log_column_tagging_action AS operation,
jsonPayload.tag_history_log_description AS details
FROM `${project}.${dataset}.${logging_table}`
WHERE jsonPayload.global_app_log = 'TAG_HISTORY_LOG'