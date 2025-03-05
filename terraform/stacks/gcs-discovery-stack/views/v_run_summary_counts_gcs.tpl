WITH dispatched AS (
  SELECT
  run_id,
  COUNT(tracking_id) AS dispatched_tracking_id_count
  FROM `${project}.${dataset}.${dispatcher_runs_gcs}`
  GROUP BY 1

)
, final AS (
    SELECT
    s.run_id,
    s.timestamp,
    d.dispatched_tracking_id_count,
    SUM(CASE WHEN s.status = 'SUCCESS' THEN 1 ELSE 0 END) AS success_trackers_count,
    SUM(CASE WHEN s.status = 'FAILED' THEN 1 ELSE 0 END) AS failed_trackers_count,
    FROM `${project}.${dataset}.${v_run_summary}` s
    -- inner join to omit the auto-dlp tagger runs as they are not originated from the dispatcher step/service and don't require lineage tracking
    INNER JOIN dispatched d ON s.run_id = d.run_id
    GROUP BY 1,2,3

)

SELECT
f.*,
f.dispatched_tracking_id_count - (f.success_trackers_count + f.failed_trackers_count) AS in_progress_trackers_count
FROM final f
ORDER BY run_id DESC