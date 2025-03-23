WITH retryable AS
(
SELECT DISTINCT
jsonPayload.global_run_id AS run_id,
jsonPayload.retryable_ex_tracking_id AS tracking_id,
resource.labels.service_name AS service_name,
jsonPayload.retryable_ex_name AS exception_name,
jsonPayload.retryable_ex_msg AS exception_message,
FROM
`${project}.${dataset}.${logging_table}`
WHERE
jsonPayload.global_app_log = 'RETRYABLE_EXCEPTIONS_LOG'
ORDER BY 2
)

SELECT *  FROM retryable