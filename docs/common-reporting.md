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

The scope of tables to be processed in this example are all tables that were under the BigQuery scan scope of a certain run. This will include tables that had DLP findings and the ones that had not.   
This query is helpful to run a gap analysis between external policy, that are created outside the bq-pii-classifier solution, and the ones detected by the solution based on DLP findings.

The service account running the remote Cloud Function must have the following roles on the tables/datasets/projects in scope:
* `roles/bigquery.metadataViewer`
* `roles/datacatalog.viewer`


```roomsql
WITH tables AS (
  SELECT
    jsonPayload.global_run_id AS run_id,
    jsonPayload.dispatched_tablespec_project AS project_id,
    jsonPayload.dispatched_tablespec_dataset AS dataset_id,
    jsonPayload.dispatched_tablespec_table AS table_id,

  FROM `bq_security_classifier.run_googleapis_com_stdout`
  WHERE jsonPayload.global_app_log = 'DISPATCHED_REQUESTS_LOG'
)
, call_remote_func AS (
  SELECT
    run_id, 
    project_id,
    dataset_id,
    table_id, 
    bq_security_classifier.remote_get_table_policy_tags(CONCAT(project_id, ".", dataset_id, ".", table_id)) AS results_json 
  FROM tables
)
, parsed_json AS (
  SELECT
    run_id,
    project_id,
    dataset_id,
    table_id, 
    JSON_EXTRACT_ARRAY(results_json, '$.columns_and_policy_tags') AS json_array
  FROM call_remote_func
)

, existing_tags AS (

 SELECT
 run_id,
 project_id,
 dataset_id,
 table_id, 
 JSON_EXTRACT_SCALAR(element, "$.column") AS column_name,
 JSON_EXTRACT_SCALAR(element, "$.policy_tag_id") AS current_policy_tag_id,
 JSON_EXTRACT_SCALAR(element, "$.policy_tag_name") AS current_policy_tag_name,
 m.policy_tag IS NOT NULL AS is_solution_owned_policy_tag
 FROM parsed_json, UNNEST(json_array) element
 LEFT JOIN bq_security_classifier.v_config_infotypes_policytags_map m ON JSON_EXTRACT_SCALAR(element, "$.policy_tag_id") = m.policy_tag 
)

, dlp_unique_findings AS (
SELECT 
SUBSTRING((SPLIT(r.job_name, "/")[OFFSET(5)]),3, 15) AS run_id,
l.record_location.record_key.big_query_key.table_reference.project_id,
l.record_location.record_key.big_query_key.table_reference.dataset_id,
l.record_location.record_key.big_query_key.table_reference.table_id,
l.record_location.field_id,
r.info_type.name AS info_type,
r.likelihood,
COUNT(1) AS findings_count
FROM bq_security_classifier.standard_dlp_results r, UNNEST(location.content_locations) l
GROUP BY 1,2,3,4,5,6,7
)
, dlp_findings_counts AS (

  SELECT
run_id,
project_id,
dataset_id,
table_id,
field_id.name AS column_name,
ARRAY_AGG(STRUCT(info_type, likelihood, findings_count)) AS dlp_findings_summary
FROM dlp_unique_findings
GROUP BY 1,2,3,4,5

)

SELECT
e.run_id,
e.project_id,
e.dataset_id,
e.table_id,
e.column_name,
e.current_policy_tag_id,
e.current_policy_tag_name,
e.is_solution_owned_policy_tag, -- if the current policy tag part of the bq-pii-classifier or not (assigned externally)
t.info_type AS solution_promoted_info_type, -- the final info type that the bq-pii-classifier assigned to this column in case of multiple dlp findings. This depends on the `promote_mixed_info_types` setting in terraform.
d.dlp_findings_summary, -- all info types that DLP detected on that column
FROM existing_tags e
LEFT JOIN bq_security_classifier.v_tagging_actions t ON e.project_id = t.project_id AND e.dataset_id = t.dataset_id AND e.table_id = t.table_id AND e.column_name = t.field_id AND e.run_id = t.run_id
LEFT JOIN dlp_findings_counts d ON  e.project_id = d.project_id AND e.dataset_id = d.dataset_id AND e.table_id = d.table_id AND e.column_name = d.column_name AND e.run_id = d.run_id

WHERE e.run_id = '<RUN-ID>'
```