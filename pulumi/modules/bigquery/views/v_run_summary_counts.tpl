SELECT
run_id,
TIMESTAMP_MILLIS(CAST(SUBSTR(run_id, 0, 13) AS INT64)) AS timestamp,
SUM(CASE WHEN status = 'COMPLETE' THEN 1 ELSE 0 END) AS complete_count,
SUM(CASE WHEN status = 'INCOMPLETE' THEN 1 ELSE 0 END) AS incomplete_count,
COUNT(1) AS total
FROM ${project}.${dataset}.${v_run_summary}
GROUP BY run_id
ORDER BY 1 DESC