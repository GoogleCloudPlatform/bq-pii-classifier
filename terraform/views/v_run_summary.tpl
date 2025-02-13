WITH  failed AS (

  SELECT
  run_id,
  tracking_id,
  'FAILED' AS status,
  'Tracker has non retryable exception(s)' AS details
  FROM `${project}.${dataset}.${v_errors_non_retryable}`
  GROUP BY 1, 2, 3
)
,
success AS (

-- Check for Tagger call completion
SELECT DISTINCT
run_id,
tracker AS tracking_id,
'SUCCESS' AS status,
'Tagger completed the expected ${inspection_templates_count} call(s) successfully' AS details
FROM
`${project}.${dataset}.${v_service_calls}`
WHERE tagger_ends = ${inspection_templates_count}
)
,
final AS
(
SELECT * FROM failed
UNION ALL
SELECT * FROM success
)


SELECT
TIMESTAMP_MILLIS(CAST(SUBSTR(final.run_id, 0, 13) AS INT64)) AS timestamp,
final.*,
FROM final ORDER BY run_id DESC, status, tracking_id