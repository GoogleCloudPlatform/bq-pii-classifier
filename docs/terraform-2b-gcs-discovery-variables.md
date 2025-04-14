### Configure DLP Discovery Scope for Cloud Storage

Set the `dlp_gcs_discovery_configurations` list to control which GCP folders and underlying buckets and objects will be scanned
by DLP. For example:

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

| Field | Required | Description                                                                                                                                                                                                                                                                                                                                                                                                                                                        |
|-------|----------|--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
|  `folder_id`     | Yes      | GCP folder to be scanned by DLP                                                                                                                                                                                                                                                                                                                                                                                                                                    |
|  `project_id_regex`     | No       | Regex for project ids to be covered by the DLP scan. If unset, it will match all projects in the folder.                                                                                                                                                                                                                                                                                                                                                           |
|  `bucket_name_regex`     | No       | Regex for bucket names (excluding the `gs://` prefix) to be covered by the DLP scan. If unset, it will match all buckets in the folder.                                                                                                                                                                                                                                                                                                                            |
|  `apply_tags`    | No       | When set to `True`, DLP discovery service will attach pre-existing data sensitivity levels tags to buckets. Defaults to `False`                                                                                                                                                                                                                                                                                                                                    |
|  `create_configuration_in_paused_state`  | No       | When set to `True`, the DLP discovery scan configuration is created in a paused state and must be resumed manually to allow confirmation and avoid DLP scan cost if there are mistakes or errors. When set to `False`, the discovery scan will start running upon creation.                                                                                                                                                                                        |
|  `reprofile_frequency`   |  No        | If you set this field, profiles are refreshed at this frequency regardless of whether the underlying data have changes. Possible values are: `UPDATE_FREQUENCY_NEVER` (default), `UPDATE_FREQUENCY_DAILY`, `UPDATE_FREQUENCY_MONTHLY`                                                                                                                                                                                                                              |
|  `reprofile_frequency_on_inspection_template_update`  | No         | How frequently data profiles can be updated when the inspection template is modified. Possible values are: `UPDATE_FREQUENCY_NEVER` (default), `UPDATE_FREQUENCY_DAILY`, `UPDATE_FREQUENCY_MONTHLY`.                                                                                                                                                                                                                                                               |
|  `included_bucket_attributes`  |  No        | Only buckets with the specified attributes will be scanned. Defaults to `["ALL_SUPPORTED_BUCKETS"]`. Each value may be one of: `ALL_SUPPORTED_BUCKETS`, `AUTOCLASS_DISABLED`, `AUTOCLASS_ENABLED`.                                                                                                                                                                                                                                                                 |
|  `included_object_attributes`  |  No        | Only objects with the specified attributes will be scanned. If an object has one of the specified attributes but is inside an excluded bucket, it will not be scanned. Defaults to `["ALL_SUPPORTED_OBJECTS"]`. A profile will be created even if no objects match the included_object_attributes. Each value may be one of: `ALL_SUPPORTED_OBJECTS`, `STANDARD`, `NEARLINE`, `COLDLINE`, `ARCHIVE`, `REGIONAL`, `MULTI_REGIONAL`, `DURABLE_REDUCED_AVAILABILITY`. |

### Configure data sensitivity tags

Previously we set the `dlp_gcs_discovery_configurations.apply_tags` field to control whether to apply custom resource tags to the scanned buckets according to
the DLP data sensitivity score (High, Moderate, Low). If needed, the default names for the sensitivity tag key and values could be overridden via:

```terraform
dlp_tag_sensitivity_level_key_name = "dlp_sensitivity_level"
dlp_tag_high_sensitivity_value_name = "high"
dlp_tag_moderate_sensitivity_value_name = "moderate"
dlp_tag_low_sensitivity_value_name = "low"
```


### Configure overwriting labels

This is a regex to identify and delete/overwrite existing GCS buckets resource labels that are previously created by the solution.
This behaviour is useful when the latest DLP findings doesn't include previously assigned labels anymore due to changes in configuration or changes in underlying data.

Alternatively, Omit the variable to use its default value that doesn't match/delete any existing labels.

```terraform
gcs_existing_labels_regex = "^contains_"
```

Recommended to omit this variable in early runs to avoid overwriting any existing labels by mistake.


### Run Terraform

Continue deployment steps as explained in this doc: [terraform-apply](terraform-4-apply.md)