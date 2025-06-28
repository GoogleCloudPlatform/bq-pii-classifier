WITH dispacthed_requests AS
(
SELECT DISTINCT
jsonPayload.global_run_id AS run_id,
jsonPayload.dispatched_tracking_id AS dispatched_tracking_id
FROM
`${project}.${dataset}.${logging_table}`
WHERE
jsonPayload.global_app_log = 'DISPATCHED_REQUESTS_LOG'

-- -- Unit testing
-- -- r1 tagger starts and doesn't finish successfully for t3
-- SELECT 'r1' AS run_id, 'r1_t1_tagged' AS dispatched_tracking_id UNION ALL
-- SELECT 'r1' AS run_id, 'r1_t2_tagged' AS dispatched_tracking_id UNION ALL
-- SELECT 'r1' AS run_id, 'r1_t3_nottagged' AS dispatched_tracking_id UNION ALL
-- -- r2 tagger doesn't start for t2
-- SELECT 'r2' AS run_id, 'r2_t1_tagged' AS dispatched_tracking_id UNION ALL
-- SELECT 'r2' AS run_id, 'r2_t2_tagged' AS dispatched_tracking_id
)



, tagger_calls AS
(
SELECT
run_id,
tracker,
inspector_starts,
inspector_ends,
tagger_starts,
tagger_ends,
FROM
`${project}.${dataset}.${v_service_calls}`

-- -- Unit tests
-- -- r1 tagger starts and doesn't finish successfully for t3
-- SELECT 'r1' AS run_id, 'r1_t1_tagged' AS tracker, 1 AS tagger_starts, 1 tagger_ends   UNION ALL
-- SELECT 'r1' AS run_id, 'r1_t2_tagged' AS tracker, 1 AS tagger_starts, 1 tagger_ends  UNION ALL
-- SELECT 'r1' AS run_id, 'r1_t3_nottagged' AS tracker, 1 AS tagger_starts, 0 tagger_ends  UNION ALL
-- -- r2 tagger doesn't start for t2
-- SELECT 'r2' AS run_id, 'r2_t1_tagged' AS tracker, 1 AS tagger_starts, 1 tagger_ends
)

-- select the dispatched trackers that has no corresponding tagger call finish marker
SELECT
d.run_id,
d.dispatched_tracking_id,
t.tagger_starts,
t.tagger_ends,
'Tagger did not run or complete successfully.' AS msg
FROM
dispacthed_requests d
LEFT JOIN tagger_calls t ON d.dispatched_tracking_id = t.tracker
WHERE t.tracker IS NULL OR t.tagger_ends = 0

UNION ALL

-- select the projects, datasets or tables that failed at the dispatcher step
SELECT DISTINCT
jsonPayload.global_run_id AS run_id,
jsonPayload.failed_dispatcher_entity_id AS entity_id,
null AS tagger_starts,
null AS tagger_ends,
jsonPayload.global_msg AS msg
FROM
`${project}.${dataset}.${logging_table}`
WHERE
jsonPayload.global_app_log = 'FAILED_DISPATCHED_REQUESTS_LOG'

