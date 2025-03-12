## Reporting

### Helpful in monitoring active runs

Monitor counts of complete vs incomplete tables for the BigQuery Discovery stack

```roomsql
SELECT * FROM `bq_pii_classifier.v_run_summary_counts`
ORDER BY run_id DESC
```

or for the GCS Discovery stack

```roomsql
SELECT * FROM `bq_pii_classifier.v_summary_counts_gcs`
ORDER BY run_id DESC
```


List all complete vs incomplete tables
```roomsql
SELECT * FROM `bq_pii_classifier.v_run_summary`
WHERE run_id = last_run_id
```


List column tagging actions across all tables

```roomsql
SELECT last_run_start_time , * FROM `bq_pii_classifier.v_tagging_actions`
WHERE run_id = last_run_id
ORDER BY tracker;
```


List computed table-level resource labels across all tables 

```roomsql
SELECT last_run_start_time , * FROM `bq_pii_classifier.v_log_label_history`
WHERE run_id = last_run_id
ORDER BY tracker;
```

### Helpful in investigating issues
 

Monitor failed runs (per table)

```roomsql
SELECT last_run_start_time , * FROM `bq_pii_classifier.v_broken_steps` 
WHERE run_id = last_run_id;
```

List Non-Retryable errors. Table trackers with Non-Retryable errors implies that these tables will not be tagged in this run. 
```roomsql
SELECT * FROM `bq_pii_classifier.v_errors_non_retryable`
WHERE run_id = last_run_id;
```

List Retryable errors. These errors are transit errors that are retried by the solution. 
```roomsql
SELECT * FROM `bq_pii_classifier.v_errors_retryable`
WHERE run_id = last_run_id;
```

Monitor the number of invocations of each Cloud Run (per table).

```roomsql
SELECT * FROM bq_pii_classifier.v_service_calls
WHERE run_id = last_run_id
ORDER BY inspector_starts DESC
```

### Execution duration per function
One could analyze or build charts on top of this dataset to monitor 
the time taken for each table request (i.e. tracker) along different steps (i.e. Inspector, Listener, Tagger). 
Please note that the Inspector duration is the time taken to submit a DLP job and not the DLP inspection itself.
```
=======
```roomsql
SELECT  
t.jsonPayload.global_run_id,
t.resource.labels.service_name,
t.jsonPayload.global_tracker,
TIMESTAMP_MILLIS(CAST(SUBSTR(MAX(t.jsonPayload.global_run_id), 0, 13) AS INT64)) run_start_time,
MIN(timestamp) AS start, 
MAX(timestamp) AS finish,
TIMESTAMP_DIFF(MAX(timestamp), MIN(timestamp), SECOND) AS duration_seconds

FROM bq_pii_classifier.run_googleapis_com_stdout t
WHERE t.jsonPayload.global_app_log = 'TRACKER_LOG'
AND t.jsonPayload.function_lifecycle_event IN ("START", "END")
GROUP BY 1,2,3
ORDER BY 1,2,3
```

### GCS Buckets Metadata 
To extract existing labels on GCS buckets along with size information, for DLP scan cost estimation, we need to use
a remote function [remote_get_buckets_metadata](../helpers/bq-remote-functions/get-buckets-metadata).

The function expects either a folder id or a project name and will lists the buckets metada under that folder or project

The service account running the remote Cloud Function must have the following permissions:
* `storage.buckets.list`, `storage.buckets.get` and `monitoring.timeSeries.list` on the data projects (could be inherited from folder or org as well)
* `resourcemanager.projects.list` on the org or folder level (if using the function on a folder level)

```roomsql
WITH remote_data AS (
   -- folder level
   SELECT `bq_pii_classifier`.remote_get_buckets_metadata("folder", "<folder id/number>") AS json_value
  -- or project level
  -- SELECT `bq_pii_classifier`.remote_get_buckets_metadata("project", "<project name>>") AS json_value
)

SELECT
JSON_VALUE(d.json_value.level) AS requested_level,
JSON_VALUE(d.json_value.entity_id) AS requested_entity_id,
JSON_EXTRACT_ARRAY(d.json_value.errors) AS errors_at_requested_entity,
JSON_VALUE(b.bucket_name) AS bucket_name,
JSON_VALUE(b.project_name) AS project_name, 
JSON_VALUE(b.size_bytes) AS size_bytes,
JSON_VALUE(b.storage_class) AS storage_class,
ARRAY(SELECT AS STRUCT JSON_VALUE(json_element, '$.key') AS key, JSON_VALUE(json_element, '$.value') AS value FROM UNNEST(JSON_EXTRACT_ARRAY(b.labels)) AS json_element) AS array_of_structs
FROM remote_data d
LEFT JOIN UNNEST(JSON_EXTRACT_ARRAY(json_value.buckets_metadata)) b
```