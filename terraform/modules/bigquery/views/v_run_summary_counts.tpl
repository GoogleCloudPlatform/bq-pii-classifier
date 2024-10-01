WITH dispatched AS (
  SELECT
  jsonPayload.global_run_id AS run_id,
  COUNT(jsonPayload.dispatched_tracking_id) AS dispatched_tracking_id_count
  FROM `${project}.${dataset}.${logging_table}`
  WHERE jsonPayload.global_app_log = 'DISPATCHED_REQUESTS_LOG'
  GROUP BY 1
)
, failed_dispatched AS (
  SELECT
  jsonPayload.global_run_id AS run_id,
  COUNT(jsonPayload.failed_dispatcher_entity_id) AS failed_dispatched_entity_count,
  FROM  `${project}.${dataset}.${logging_table}`
  WHERE jsonPayload.global_app_log = 'FAILED_DISPATCHED_REQUESTS_LOG'
  GROUP BY 1
)
, final AS (
    SELECT
    s.run_id,
    s.timestamp,
    d.dispatched_tracking_id_count,
    fd.failed_dispatched_entity_count,
    SUM(CASE WHEN s.status = 'SUCCESS' THEN 1 ELSE 0 END) AS success_trackers_count,
    SUM(CASE WHEN s.status = 'FAILED' THEN 1 ELSE 0 END) AS failed_trackers_count,
    FROM `${project}.${dataset}.${v_run_summary}` s
    LEFT JOIN dispatched d ON s.run_id = d.run_id
    LEFT JOIN failed_dispatched fd ON s.run_id = fd.run_id
    GROUP BY 1,2,3,4

)

SELECT
f.*,
f.dispatched_tracking_id_count - (f.success_trackers_count + f.failed_trackers_count) AS in_progress_trackers_count
FROM final f
ORDER BY run_id DESC