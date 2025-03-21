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


List column tagging actions across all tables

```roomsql
SELECT  * FROM `bq_pii_classifier.v_tagging_actions`
WHERE run_id = RUN_ID
ORDER BY tracker;
```


List computed table-level resource labels across all tables 

```roomsql
SELECT  * FROM `bq_pii_classifier.v_log_label_history`
WHERE run_id = RUN_ID
ORDER BY tracker;
```

### Helpful in investigating issues
 

Tracking log messages for a particular entity (e.g. table or bucket).
```roomsql
SELECT 
    jsonPayload.global_run_id,
    jsonPayload.global_tracker,
    jsonPayload.global_entity_id,
    jsonPayload.global_app_log,
    resource.labels.service_name,
    jsonPayload.global_logger_name,
    jsonPayload.global_msg
FROM `bq_pii_classifier.run_googleapis_com_stdout` l
WHERE jsonPayload.global_entity_id LIKE '%buckets/BUCKET_NAME'
AND jsonPayload.global_run_id = TAGGING_DISPATCHER_RUN_ID
ORDER BY timestamp ASC
```

List Non-Retryable errors. Table trackers with Non-Retryable errors implies that these tables will not be tagged in this run. 
```roomsql
SELECT * FROM `bq_pii_classifier.v_errors_non_retryable`
WHERE run_id = RUN_ID;
```

List Retryable errors. These errors are transit errors that are retried by the solution. 
```roomsql
SELECT * FROM `bq_pii_classifier.v_errors_retryable`
WHERE run_id = RUN_ID;
```

Monitor the number of invocations of each Cloud Run (per table).

```roomsql
SELECT * FROM bq_pii_classifier.v_service_calls
WHERE run_id = RUN_ID
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

FROM bq_pii_classifier.run_googleapis_com_stdout t
WHERE t.jsonPayload.global_app_log = 'TRACKER_LOG'
AND t.jsonPayload.function_lifecycle_event IN ("START", "END")
GROUP BY 1,2,3
ORDER BY 1,2,3
```

### GCS Buckets Metadata 
To extract existing labels on GCS buckets along with size information, for DLP scan cost estimation, we need to use
a remote function [remote_get_buckets_metadata](../helpers/bq-remote-functions/get-buckets-metadata).

The function expects either a folder id or a project name and will list the buckets metadata under that folder or project

The service account running the remote Cloud Function must have the following permissions:
* `storage.buckets.list`, `storage.buckets.get` and `monitoring.timeSeries.list` on the data projects (could be inherited from folder or org as well)
* `resourcemanager.projects.list` on the org or folder level (if using the function on a folder level)

The above permissions are granted by Terraform in the [org-and-folder-permissions-for-gcs-discovery-stack](../terraform/modules/org-and-folder-permissions-for-gcs-discovery-stack) module.

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
ARRAY(SELECT AS STRUCT JSON_VALUE(json_element, '$.key') AS key, JSON_VALUE(json_element, '$.value') AS value FROM UNNEST(JSON_EXTRACT_ARRAY(b.labels)) AS json_element) AS labels
FROM remote_data d
LEFT JOIN UNNEST(JSON_EXTRACT_ARRAY(json_value.buckets_metadata)) b
```

### Attached policy Tags to tables
To extract policy tags from tables we need to use a remote function [remote_get_table_policy_tags](../helpers/bq-remote-functions/get-policy-tags).
The function expected a table spec and returns a JSON in the form of a list containing each column with its policy tag info.

The scope of tables to be processed in this example are all tables that were under the BigQuery scan scope of a certain tagging run (invoked by the Tagging Dispatcher Service). 
This will include tables profiled by DLP whether they have info types detected or not.   

This query is helpful to run a gap analysis between external policy, that are created outside the bq-pii-classifier solution, and the ones detected by the solution based on DLP findings.

The service account running the remote Cloud Function must have the following roles on the tables/datasets/projects in scope:
* `roles/bigquery.metadataViewer`
* `roles/datacatalog.viewer`

The above permissions are granted by Terraform in the [org-and-folder-permissions-for-bq-discovery-stack](../terraform/modules/org-and-folder-permissions-for-bq-discovery-stack) module.


```roomsql
WITH tables AS (
  SELECT
    run_id,
    project_id,
    dataset_id,
    table_id
  FROM `bq_pii_classifier.dispatcher_runs_bigquery`
)
, call_remote_func AS (
  SELECT
    run_id, 
    project_id,
    dataset_id,
    table_id, 
    bq_pii_classifier.remote_get_table_policy_tags(CONCAT(project_id, ".", dataset_id, ".", table_id)) AS results_json 
  FROM tables
)
, parsed_json AS (
  SELECT
    run_id,
    project_id,
    dataset_id,
    table_id, 
    JSON_EXTRACT_ARRAY(results_json, '$.columns_and_policy_tags') AS json_array,
    JSON_EXTRACT(results_json, '$.error') AS get_table_schema_error
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
 get_table_schema_error,
 m.policy_tag IS NOT NULL AS is_solution_owned_policy_tag
 FROM parsed_json
 LEFT JOIN UNNEST(json_array) element
 LEFT JOIN bq_pii_classifier.v_config_infotypes_policytags_map m ON JSON_EXTRACT_SCALAR(element, "$.policy_tag_id") = m.policy_tag 
)


SELECT
e.run_id,
e.project_id,
e.dataset_id,
e.table_id,
e.get_table_schema_error,
e.column_name,
e.current_policy_tag_id,
e.current_policy_tag_name,
e.is_solution_owned_policy_tag, -- if the current policy tag part of the bq-pii-classifier or not (assigned externally)
FROM existing_tags e
LEFT JOIN bq_pii_classifier.v_tagging_actions t ON e.project_id = t.project_id AND e.dataset_id = t.dataset_id AND e.table_id = t.table_id AND e.column_name = t.field_id AND e.run_id = t.run_id
WHERE e.run_id = TAGGING_DISPATCHER_RUN_ID
```