SELECT
TIMESTAMP_MILLIS(CAST(SUBSTR(jsonPayload.global_run_id, 0, 13) AS INT64)) AS start_time,
jsonPayload.global_run_id AS run_id,
jsonPayload.global_tracker AS tracker,
jsonPayload.global_logger_name AS function_name,
jsonPayload.function_lifecycle_functionnumber AS function_number,
jsonPayload.function_lifecycle_event AS step
FROM `${project}.${dataset}.${logging_table}`
WHERE jsonPayload.global_app_log = 'TRACKER_LOG'

