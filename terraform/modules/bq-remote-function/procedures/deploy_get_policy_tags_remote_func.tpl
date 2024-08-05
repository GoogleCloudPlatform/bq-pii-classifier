CREATE OR REPLACE FUNCTION `${project}.${dataset}`.${function_name}(table_spec STRING) RETURNS JSON

REMOTE WITH CONNECTION `${project}.${connection_region}.${connection_name}`
OPTIONS (
  endpoint = "${cloud_function_url}"
);