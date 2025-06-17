<!-- TOC -->
* [Module - DLP](#module---dlp)
  * [Variables](#variables)
    * [Configure Basic Variables](#configure-basic-variables)
    * [Configure DLP global template](#configure-dlp-global-template)
    * [Configure data sensitivity tags](#configure-data-sensitivity-tags)
    * [Built-in InfoTypes](#built-in-infotypes)
    * [GCS Discovery Variables](#gcs-discovery-variables)
    * [BigQuery Discovery Variables](#bigquery-discovery-variables)
    * [Configure Custom InfoTypes (Optional)](#configure-custom-infotypes-optional)
<!-- TOC -->
# Module - DLP

## Variables

### Configure Basic Variables

```terraform
org_id = 0 # < GCP organization ID that will host the DLP discovery service configuration >
application_project = "<GCP project to host the application internal resources (e.g. DLP, Cloud Run, Service Accounts, etc)>"
publishing_project = "<GCP project to host external/shared resources such as DLP results and monitoring views>"
data_region = "<GCP region to store application data (e.g. DLP results, logs, etc)>"
source_data_regions  = ["Supported GCP regions for DLP inspection>"]
```

### Configure DLP global template

DLP inspection templates are deployed to all `source_data_regions` by default.
Set this to `true` to add the `global` region to the list to be used to inspect
resources in any region if you're not sure where the data is in your org or to
reduce the number of templates.

```terraform
deploy_dlp_inspection_template_to_global_region = true
```

### Configure data sensitivity tags

Set (or link) the below variables to the namespaced names of the DLP tags
created by the `tags` module.

```terraform
dlp_tag_high_sensitivity_value_namespaced_name = "123/eip-cloud-dlp-sensitivity-level/high"
dlp_tag_moderate_sensitivity_value_namespaced_name = "123/eip-cloud-dlp-sensitivity-level/moderate"
dlp_tag_low_sensitivity_value_namespaced_name = "123/eip-cloud-dlp-sensitivity-level/low"
```

### Built-in InfoTypes

Set the `built_in_info_types` to define which Cloud DLP infotypes should be
added to the inspection template used to scan data resources. For example:

```terraform
  built_in_info_types = [
    {
      info_type = "DEMOGRAPHIC_DATA"
    },
    {
      info_type = "FINANCIAL_ID"
    }
    ... etc
  ]
```

### GCS Discovery Variables

Set the `dlp_gcs_discovery_configurations` list to control which GCP folders and
underlying buckets and objects will be scanned by DLP. For example:

```terraform
dlp_gcs_discovery_configurations = [
  {
    folder_id = 123
    project_id_regex = "^project-name$"
    bucket_name_regex = ".*"
    apply_tags = true
    create_configuration_in_paused_state = false
    reprofile_frequency = "UPDATE_FREQUENCY_NEVER"
    reprofile_frequency_on_inspection_template_update =  "UPDATE_FREQUENCY_NEVER"
    included_bucket_attributes =  ["ALL_SUPPORTED_BUCKETS"]
    included_object_attributes = ["ALL_SUPPORTED_OBJECTS"]
  },
  {
    folder_id = 456
    # all other fields are set to their defaults
  }
]
```

The full list of fields and descriptions are below:

Field                                               | Required | Description
--------------------------------------------------- | -------- | -----------
`folder_id`                                         | Yes      | GCP folder to be scanned by DLP
`project_id_regex`                                  | No       | Regex for project ids to be covered by the DLP scan. If unset, it will match all projects in the folder.
`bucket_name_regex`                                 | No       | Regex for bucket names (excluding the `gs://` prefix) to be covered by the DLP scan. If unset, it will match all buckets in the folder.
`apply_tags`                                        | No       | When set to `True`, DLP discovery service will attach pre-existing data sensitivity levels tags to buckets. Defaults to `False`
`create_configuration_in_paused_state`              | No       | When set to `True`, the DLP discovery scan configuration is created in a paused state and must be resumed manually to allow confirmation and avoid DLP scan cost if there are mistakes or errors. When set to `False`, the discovery scan will start running upon creation.
`reprofile_frequency`                               | No       | If you set this field, profiles are refreshed at this frequency regardless of whether the underlying data have changes. Possible values are: `UPDATE_FREQUENCY_NEVER` (default), `UPDATE_FREQUENCY_DAILY`, `UPDATE_FREQUENCY_MONTHLY`
`reprofile_frequency_on_inspection_template_update` | No       | How frequently data profiles can be updated when the inspection template is modified. Possible values are: `UPDATE_FREQUENCY_NEVER` (default), `UPDATE_FREQUENCY_DAILY`, `UPDATE_FREQUENCY_MONTHLY`.
`included_bucket_attributes`                        | No       | Only buckets with the specified attributes will be scanned. Defaults to `["ALL_SUPPORTED_BUCKETS"]`. Each value may be one of: `ALL_SUPPORTED_BUCKETS`, `AUTOCLASS_DISABLED`, `AUTOCLASS_ENABLED`.
`included_object_attributes`                        | No       | Only objects with the specified attributes will be scanned. If an object has one of the specified attributes but is inside an excluded bucket, it will not be scanned. Defaults to `["ALL_SUPPORTED_OBJECTS"]`. A profile will be created even if no objects match the included_object_attributes. Each value may be one of: `ALL_SUPPORTED_OBJECTS`, `STANDARD`, `NEARLINE`, `COLDLINE`, `ARCHIVE`, `REGIONAL`, `MULTI_REGIONAL`, `DURABLE_REDUCED_AVAILABILITY`.

### BigQuery Discovery Variables

Set the `dlp_bq_discovery_configurations` list to control which GCP folders and
underlying datasets and tables will be scanned by DLP. For example:

```terraform
dlp_gcs_discovery_configurations = [
  {
    folder_id = 123,
    project_id_regex = "^project_name$"
    dataset_regex = "^dataset_name$"
    table_regex = ".*"
    apply_tags = true
    create_configuration_in_paused_state = false
    table_types = ["BIG_QUERY_TABLE_TYPE_TABLE", "BIG_QUERY_TABLE_TYPE_EXTERNAL_BIG_LAKE"]
    reprofile_frequency_on_table_schema_update = "UPDATE_FREQUENCY_NEVER"
    reprofile_frequency_on_table_data_update = "UPDATE_FREQUENCY_NEVER"
    reprofile_frequency_on_inspection_template_update = "UPDATE_FREQUENCY_NEVER"
    reprofile_types_on_schema_update = ["SCHEMA_NEW_COLUMNS"]
    reprofile_types_on_table_data_update = ["TABLE_MODIFIED_TIMESTAMP"]
  },
  {
    folder_id = 456
    # all other fields are set to their defaults
  }
]
```

The full list of fields and descriptions are below:

Field                                               | Required | Description
--------------------------------------------------- | -------- | -----------
`folder_id`                                         | Yes      | GCP folder to be scanned by DLP
`project_id_regex`                                  | No       | Regex for project ids to be covered by the DLP scan. If unset, it will match all projects in the folder.
`dataset_regex`                                     | No       | Regex for datasets to be covered by the DLP scan. If unset, it will match all datasets in the folder.
`table_regex`                                       | No       | Regex for tables to be covered by the DLP scan. If unset, it will match all tables in the folder.
`apply_tags`                                        | No       | When set to `True`, DLP discovery service will attach pre-existing data sensitivity levels tags to tables. Defaults to `False`
`create_configuration_in_paused_state`              | No       | When set to `True`, the DLP discovery scan configuration is created in a paused state and must be resumed manually to allow confirmation and avoid DLP scan cost if there are mistakes or errors. When set to `False`, the discovery scan will start running upon creation.
`table_types`                                       | No       | Restrict dlp discovery service for BigQuery to specific table types. Defaults to `["BIG_QUERY_TABLE_TYPE_TABLE", "BIG_QUERY_TABLE_TYPE_EXTERNAL_BIG_LAKE"]`
`reprofile_frequency_on_table_schema_update`        | No       | How frequently data profiles can be updated when a table schema is modified (i.e. columns). Possible values are: `UPDATE_FREQUENCY_NEVER` (default), `UPDATE_FREQUENCY_DAILY`, `UPDATE_FREQUENCY_MONTHLY`.
`reprofile_frequency_on_table_data_update`          | No       | How frequently data profiles can be updated when a table data is modified (i.e. rows). Possible values are: `UPDATE_FREQUENCY_NEVER` (default), `UPDATE_FREQUENCY_DAILY`, `UPDATE_FREQUENCY_MONTHLY`.
`reprofile_frequency_on_inspection_template_update` | No       | How frequently data profiles can be updated when the inspection template is modified. Possible values are: `UPDATE_FREQUENCY_NEVER` (default), `UPDATE_FREQUENCY_DAILY`, `UPDATE_FREQUENCY_MONTHLY`.
`reprofile_types_on_schema_update`                  | No       | A list of type of events to consider when deciding if the tables schema has been modified and should have the profile updated. Each value may be one of: `SCHEMA_NEW_COLUMNS` (default), `SCHEMA_REMOVED_COLUMNS`
`reprofile_types_on_table_data_update`              | No       | A list type of events to consider when deciding if the table has been modified and should have the profile updated. Each value may be one of: `TABLE_MODIFIED_TIMESTAMP` (default)

### Configure Custom InfoTypes (Optional)

One could define custom InfoTypes to be used by DLP for inspecting data assets.
Supported Info Types are dictionaries and/or regular expressions.

Dictionaries are defined as follows:

```terraform
custom_info_types_dictionaries = [
   {
      name       = "CUSTOM_PAYMENT_METHOD"
      likelihood = "LIKELY"
      dictionary = ["Debit Card", "Credit Card"]
   },
   ... etc
]
```

While regular expressions are defined as follows:

```terraform
custom_info_types_regex = [
  {
    name       = "CUSTOM_EMAIL"
    likelihood = "LIKELY"
    regex      = "[A-Z0-9._%+-]+@[A-Z0-9.-]+\\.[A-Z]{2,4}"
  }
  ... etc
]
```

`likelihood` is the matching likelihood to return for this Custom InfoType and
could be any of the following values `[VERY_UNLIKELY, UNLIKELY, POSSIBLE,
LIKELY, VERY_LIKELY]`

If no custom InfoTypes are required, omit these variables.
