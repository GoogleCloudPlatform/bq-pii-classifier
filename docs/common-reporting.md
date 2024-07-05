## Reporting

Get the latest run_id

```roomsql
DECLARE last_run_id STRING;
DECLARE last_run_start_time TIMESTAMP;

SET (last_run_id, last_run_start_time ) = (SELECT AS STRUCT TRIM(MAX(run_id)), TIMESTAMP_MILLIS(CAST(SUBSTR(MAX(run_id), 0, 13) AS INT64)) FROM `bq_security_classifier.v_steps`);

SELECT last_run_id, last_run_start_time;
```

### Helpful in monitoring active runs

Monitor counts of complete vs incomplete tables
```roomsql
SELECT * FROM `bq_security_classifier.v_run_summary_counts`
WHERE run_id = last_run_id
```

List all complete vs incomplete tables
```roomsql
SELECT * FROM `bq_security_classifier.v_run_summary`
WHERE run_id = last_run_id
```


List column tagging actions across all tables

```roomsql
SELECT last_run_start_time , * FROM `bq_security_classifier.v_tagging_actions`
WHERE run_id = last_run_id
ORDER BY tracker;
```


List computed table-level resource labels accrss all tables 

```roomsql
SELECT last_run_start_time , * FROM `bq_security_classifier.v_log_label_history`
WHERE run_id = last_run_id
ORDER BY tracker;
```

### Helpful in investigating issues
 

Monitor failed runs (per table)

```roomsql
SELECT last_run_start_time , * FROM `bq_security_classifier.v_broken_steps` 
WHERE run_id = last_run_id;
```

List Non-Retryable errors. Table trackers with Non-Retryable errors implies that these tables will not be tagged in this run. 
```roomsql
SELECT * FROM `bq_security_classifier.v_errors_non_retryable`
WHERE run_id = last_run_id;
```

List Retryable errors. These errors are transit errors that are retried by the solution. 
```roomsql
SELECT * FROM `bq_security_classifier.v_errors_retryable`
WHERE run_id = last_run_id;
```

Monitor the number of invocations of each Cloud Run (per table).

```roomsql
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
```roomsql
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

### Execution duration per function
One could analyze or build charts on top of this dataset to monitor 
the time taken for each table request (i.e. tracker) along different steps (i.e. Inspector, Listener, Tagger). 
Please note that the Inspector duration is the time taken to submit a DLP job and not the DLP inspection itself.
```roomsql
SELECT  
t.jsonPayload.global_run_id,
t.resource.labels.service_name,
t.jsonPayload.global_tracker,
TIMESTAMP_MILLIS(CAST(SUBSTR(MAX(t.jsonPayload.global_run_id), 0, 13) AS INT64)) run_start_time,
MIN(timestamp) AS start, 
MAX(timestamp) AS finish,
TIMESTAMP_DIFF(MAX(timestamp), MIN(timestamp), SECOND) AS duration_seconds

FROM bq_security_classifier.run_googleapis_com_stdout t
WHERE t.jsonPayload.global_app_log = 'TRACKER_LOG'
AND t.jsonPayload.function_lifecycle_event IN ("START", "END")
GROUP BY 1,2,3
ORDER BY 1,2,3
```

### Attached policy Tags to tables
To extract policy tags from tables we need to use a remote function [remote_get_table_policy_tags](../helpers/bq-remote-functions/get-policy-tags).
The function expected a table spec and returns a JSON in the form of a list containing each column with its policy tag info.
One could replace the demo_tables with real data from the INFORMATION_SCHEMA.TABLES or manual input.

The service account running the remote Cloud Function must have the following roles on the tables/datasets/projects in scope:
* `roles/bigquery.metadataViewer`
* `roles/datacatalog.viewer`

```roomsql
WITH demo_tables AS (
  SELECT 'project.dataset.table_1' AS table_spec
  UNION ALL
  SELECT 'project.dataset.table_2' AS table_spec
)
, call_remote_func AS (
  SELECT 
    table_spec, 
    bq_security_classifier.remote_get_table_policy_tags(table_spec) AS results_json 
  FROM demo_tables
)
, parsed_json AS (
  SELECT
    table_spec,
    JSON_EXTRACT_ARRAY(results_json, '$.columns_and_policy_tags') AS json_array
  FROM call_remote_func
)

SELECT
 table_spec,
 JSON_EXTRACT_SCALAR(element, "$.column") AS column_name,
 JSON_EXTRACT_SCALAR(element, "$.policy_tag_id") AS policy_tag_id,
 JSON_EXTRACT_SCALAR(element, "$.policy_tag_name") AS policy_tag_name
FROM parsed_json, UNNEST(json_array) element
```