CREATE OR REPLACE FUNCTION `${project}.${dataset}`.${function_name}(level STRING, entity_id STRING) RETURNS JSON

REMOTE WITH CONNECTION `${project}.${connection_region}.${connection_name}`
OPTIONS (
  endpoint = "${cloud_function_url}",
  max_batching_rows = 100
);