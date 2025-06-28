WITH broken AS
(
-- Check for Tagger call in-completion (yet)
SELECT
run_id,
TIMESTAMP_MILLIS(CAST(SUBSTR(run_id, 0, 13) AS INT64)) AS timestamp,
s.dispatched_tracking_id AS tracking_id,
'INCOMPLETE' AS status,
msg AS details
FROM `${project}.${dataset}.${v_broken_steps}` s
),
success AS (

-- Check for Tagger call completion
SELECT DISTINCT
run_id,
TIMESTAMP_MILLIS(CAST(SUBSTR(run_id, 0, 13) AS INT64)) AS timestamp,
tracker AS tracking_id,
'COMPLETE' AS status,
'Tagger Completed Successfully' AS details
FROM
`${project}.${dataset}.${v_service_calls}`
WHERE tagger_ends > 0

)
,
final AS
(
SELECT * FROM broken
UNION ALL
SELECT * FROM success
)


SELECT * FROM final ORDER BY run_id DESC, status, tracking_id