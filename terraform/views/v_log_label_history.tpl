SELECT
TIMESTAMP_MILLIS(CAST(SUBSTR(jsonPayload.global_run_id, 0, 13) AS INT64)) AS start_time,
jsonPayload.global_run_id AS run_id,
jsonPayload.global_tracker AS tracker,
jsonPayload.labels_history_log_project_id AS project_id,
jsonPayload.labels_history_log_dataset_id AS dataset_id,
jsonPayload.labels_history_log_table_id AS table_id,
jsonPayload.labels_history_log_label_key AS label_key,
jsonPayload.labels_history_log_label_value AS label_value,
jsonPayload.labels_history_log_is_dry_run AS is_dry_run_labels,
FROM `${project}.${dataset}.${logging_table}`
WHERE jsonPayload.global_app_log = 'LABEL_HISTORY_LOG'