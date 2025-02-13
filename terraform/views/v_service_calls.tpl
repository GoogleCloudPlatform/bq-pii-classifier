SELECT
run_id,
tracker,
SUM(CASE WHEN step = 'START'  AND function_number = 2 THEN 1 ELSE 0 END) AS inspector_starts,
SUM(CASE WHEN step = 'END' AND function_number = 2 THEN 1 ELSE 0 END) AS inspector_ends,
SUM(CASE WHEN step = 'START'  AND function_number = 3 THEN 1 ELSE 0 END) AS tagger_starts,
SUM(CASE WHEN step = 'END' AND function_number = 3 THEN 1 ELSE 0 END) AS tagger_ends,
FROM
`${project}.${dataset}.${logging_view_steps}`
WHERE function_number > 1
GROUP BY 1,2