## Reporting

Get the latest run_id

```
DECLARE last_run_id STRING;
DECLARE last_run_start_time TIMESTAMP;

SET (last_run_id, last_run_start_time ) = (SELECT AS STRUCT TRIM(MAX(run_id)), TIMESTAMP_MILLIS(CAST(SUBSTR(MAX(run_id), 0, 13) AS INT64)) FROM `bq_security_classifier.v_steps`);

SELECT last_run_id, last_run_start_time;
```

### Helpful in monitoring active runs

Monitor counts of complete vs incomplete tables
```
SELECT * FROM `bq_security_classifier.v_run_summary_counts`
WHERE run_id = last_run_id
```

List all complete vs incomplete tables
```
SELECT * FROM `bq_security_classifier.v_run_summary`
WHERE run_id = last_run_id
```


List column tagging actions across all tables

```
SELECT last_run_start_time , * FROM `bq_security_classifier.v_tagging_actions`
WHERE run_id = last_run_id
ORDER BY tracker;
```


### Helpful in investigating issues
 

Monitor failed runs (per table)

```
SELECT last_run_start_time , * FROM `bq_security_classifier.v_broken_steps` 
WHERE run_id = last_run_id;

```

List Non-Retryable errors. Table trackers with Non-Retryable errors implies that these tables will not be tagged in this run. 
```
SELECT * FROM `bq_security_classifier.v_errors_non_retryable`
WHERE run_id = last_run_id;
```

List Retryable errors. These errors are transit errors that are retried by the solution. 
```
SELECT * FROM `bq_security_classifier.v_errors_retryable`
WHERE run_id = last_run_id;
```

Monitor the number of invocations of each Cloud Run (per table).

```
SELECT * FROM bq_security_classifier.v_service_calls
WHERE run_id = last_run_id
ORDER BY inspector_starts DESC
```

### Tracking-Id mapping
Tracking Ids are created by the dispatcher (the first step of
processing) for every table request to track its progress
across the entire solution (e.g. inspection, tagging, etc). They are randomly generated UUID.  

Most views will show the tracking_id which on its own not very indicative
of which table request. However, there is a mapping view `v_tracking_id_to_table_map`
that contains the mapping between tracking ids and tables. It could be
used as in the following example:
```
SELECT 
s.*,
m.tablespec,
m.project_id,
m.dataset_id,
m.table_id
FROM `bq_security_classifier.v_run_summary` s
LEFT JOIN `bq_security_classifier.v_tracking_id_to_table_map` m ON s.tracking_id = m.tracking_id
WHERE s.run_id = '1643760012003-I'
```