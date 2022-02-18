WITH broken AS
(
SELECT
run_id,
TIMESTAMP_MILLIS(CAST(SUBSTR(run_id, 0, 13) AS INT64)) AS timestamp,
s.dispatched_tracking_id AS tracking_id,
'INCOMPLETE' AS status,
msg AS details
FROM `${project}.${dataset}.${v_broken_steps}` s
),
success AS (
SELECT DISTINCT
run_id,
TIMESTAMP_MILLIS(CAST(SUBSTR(run_id, 0, 13) AS INT64)) AS timestamp,
tracker AS tracking_id,
'COMPLETE' AS status,
'Table was tagged sucessfully' AS details
FROM `${project}.${dataset}.${v_tagging_actions}`
)
,
final AS
(
SELECT * FROM broken
UNION ALL
SELECT * FROM success
)


SELECT * FROM final ORDER BY run_id DESC, status, tracking_id