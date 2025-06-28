SELECT DISTINCT
jsonPayload.global_run_id AS run_id,
jsonPayload.dispatched_tracking_id AS tracking_id,
jsonPayload.dispatched_tablespec AS tablespec,
jsonPayload.dispatched_tablespec_project AS project_id,
jsonPayload.dispatched_tablespec_dataset AS dataset_id,
jsonPayload.dispatched_tablespec_table AS table_id
FROM
`${project}.${dataset}.${logging_table}`
WHERE
jsonPayload.global_app_log = 'DISPATCHED_REQUESTS_LOG'