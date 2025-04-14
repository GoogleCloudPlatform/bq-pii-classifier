### Configure DLP Discovery Scope for BigQuery

Set the `dlp_bq_discovery_configurations` list to control which GCP folders and underlying datasets and tables will be scanned
by DLP. For example:

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

| Field                                               | Required | Description                                                                                                                                                                                                                                                                 |
|-----------------------------------------------------|----------|-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `folder_id`                                         | Yes      | GCP folder to be scanned by DLP                                                                                                                                                                                                                                             |
| `project_id_regex`                                  | No       | Regex for project ids to be covered by the DLP scan. If unset, it will match all projects in the folder.                                                                                                                                                                    |
| `dataset_regex`                                     | No       | Regex for datasets to be covered by the DLP scan. If unset, it will match all datasets in the folder.                                                                                                                                                                       |
| `table_regex`                                       | No       | Regex for tables to be covered by the DLP scan. If unset, it will match all tables in the folder.                                                                                                                                                                           |
| `apply_tags`                                        | No       | When set to `True`, DLP discovery service will attach pre-existing data sensitivity levels tags to buckets. Defaults to `False`                                                                                                                                             |
| `create_configuration_in_paused_state`              | No       | When set to `True`, the DLP discovery scan configuration is created in a paused state and must be resumed manually to allow confirmation and avoid DLP scan cost if there are mistakes or errors. When set to `False`, the discovery scan will start running upon creation. |
| `table_types`                                       | No         | Restrict dlp discovery service for BigQuery to specific table types. Defaults to `["BIG_QUERY_TABLE_TYPE_TABLE", "BIG_QUERY_TABLE_TYPE_EXTERNAL_BIG_LAKE"]`                                                                                                                 |
| `reprofile_frequency_on_table_schema_update`                                      | No         | How frequently data profiles can be updated when a table schema is modified (i.e. columns). Possible values are: `UPDATE_FREQUENCY_NEVER` (default), `UPDATE_FREQUENCY_DAILY`, `UPDATE_FREQUENCY_MONTHLY`.                                                                  |
| `reprofile_frequency_on_table_data_update`                                       | No         | How frequently data profiles can be updated when a table data is modified (i.e. rows). Possible values are: `UPDATE_FREQUENCY_NEVER` (default), `UPDATE_FREQUENCY_DAILY`, `UPDATE_FREQUENCY_MONTHLY`.                                                                       |
| `reprofile_frequency_on_inspection_template_update` | No         | How frequently data profiles can be updated when the inspection template is modified. Possible values are: `UPDATE_FREQUENCY_NEVER` (default), `UPDATE_FREQUENCY_DAILY`, `UPDATE_FREQUENCY_MONTHLY`.                                                                        |
| `reprofile_types_on_schema_update` | No         | A list of type of events to consider when deciding if the tables schema has been modified and should have the profile updated. Each value may be one of: `SCHEMA_NEW_COLUMNS` (default), `SCHEMA_REMOVED_COLUMNS`                                                           |
| `reprofile_types_on_table_data_update` | No         | A list type of events to consider when deciding if the table has been modified and should have the profile updated. Each value may be one of: `TABLE_MODIFIED_TIMESTAMP` (default)                                                                                          |


### Configure data sensitivity tags

Previously we set the `dlp_bq_discovery_configurations.apply_tags` field to control whether to apply custom resource tags to the scanned tables according to
the DLP data sensitivity score (High, Moderate, Low). If needed, the default names for the sensitivity tag key and values could be overridden via:

```terraform
dlp_tag_sensitivity_level_key_name = "dlp_sensitivity_level"
dlp_tag_high_sensitivity_value_name = "high"
dlp_tag_moderate_sensitivity_value_name = "moderate"
dlp_tag_low_sensitivity_value_name = "low"
```


### Configure overwriting labels (Optional)

Set to a regex to be used to identify and delete/overwrite existing BigQuery tables resource labels that are previously created by the solution.
This behaviour is useful when the latest DLP findings doesn't include previously assigned labels anymore due o change in configuration or change in underlying data.

Alternatively, Omit the variable to use its default value that doesn't delete any existing labels.
```terraform
bq_existing_labels_regex = "^contains_"
```

Recommended to omit this variable in early runs to avoid overwriting any existing labels by mistake.

### Configure DryRun Tags option

By setting `is_dry_run_tags = true` the solution will scan BigQuery tables
for PII data, store the scan result, but it will not apply policy tags to columns.
Instead, the "Tagger" function will only log [actions](../library/src/main/java/com/google/cloud/pso/bq_pii_classifier/functions/tagger/ColumnTaggingAction.java).
These logs can be monitored via the `v_log_tag_history` monitoring view


```terraform
is_dry_run_tags = false
```


### Configure policy tags taxonomies enforcement

Even if policy tags are attached to columns, there is still an option to enforce 
access control via the tag or to bypass it. Set this variable to `["FINE_GRAINED_ACCESS_CONTROL"]` to enforce access control via policy tags. Set to `[]` bypass.

```terraform
data_catalog_taxonomy_activated_policy_types = ["FINE_GRAINED_ACCESS_CONTROL"]
```


### Configure Domain Mapping (Optional)

A one-to-one mapping between GCP projects and/or BigQuery datasets and domains.
Domains are logical groupings that determine access control boundaries. For example, if  “Marketing” and “Finance” are domains this means that marketing PII readers can only read their PII data but can’t read finance PII data.

For each configured “domain” a corresponding taxonomy will be generated in Cloud Data Catalog. Each taxonomy will contain the policy tags defined in Info Type - Policy Tag Mapping in the hierarchy defined in Terraform (adjustable)

You can define one domain per project that will be applied to all
BigQuery tables inside it. Additionally, you can overwrite this default project
domain on dataset level (e.g. in case of a DWH project having data from different domains).


```terraform

domain_mapping = [
  {
    project = "marketing-project",
    domain = "marketing"
  },
  {
    project = "dwh-project",
    domain = "dwh"
    datasets = [
      {
        name = "demo_marketing",
        domain = "marketing"
      },
      {
        name = "demo_finance",
        domain = "finance"
      }
    ]
  }
]
```

Omit this variable, or set to `domain_mapping = []` to use one default global domain under the hood.

### Configure domain-IAM mapping (Optional)

A mapping between domains/classifications and IAM users and/or groups.
This will determine who has access to PII data under each domain and classification.

This is a dictionary of dictionaries. The first dict is in the format "<domain> = dict"
while the second level of dicts are in the format of "<classification> = [list of IAM members]". Both the "<domain>" and "<classification>"
are the ones configured in `domain_mapping`.

For users: "user:username@example.com"
For groups: "group:groupname@example.com"
For service accounts: "serviceAccount:saname@example.com"

For example:

```terraform

iam_mapping = {

  marketing = {
    P1 = ["user:marketing-p1-reader@example.com"],
    P2 = ["user:marketing-p2-reader@example.com"]
  },

  finance = {
    P1 = ["user:finance-p1-reader@example.com"],
    P2 = ["user:finance-p2-reader@example.com"]
  },

  dwh = {
    P1 = ["user:dwh-p1-reader@example.com"],
    P2 = ["user:dwh-p2-reader@example.com"]
  }
}

```

Omit this variable, or set to `iam_mapping = {}`, to skip adding IAM members to policy tag taxonomies (e.g. if the solution is in dry-run mode `is_dry_run_tags`)

#### Configure what to do with Mixed PII

The `promote_dlp_other_matches` setting will determine how the solution picks only one info type and policy tag
per column for the ones that have multiple info types detected by DLP.


* In case of `true`:    
  The solution will include the `other_matches` that DLP detects for a particular column to promote one policy tag per column. 
  If a main info type is detected, then it will be used. Else, if only one "other matches" is found, it will be used. Otherwise, If more than one Info Type is detected in "other matches", "MIXED" policy tag will be applied to that column.
* In case of `false`:   
  The solution will only rely on the main info type detected by DLP, or none if DLP doesn't report one.


Internally, this "promotion" logic is defined by this function: [computeFinalInfo Type](../library/src/main/java/com/google/cloud/pso/bq_pii_classifier/functions/tagger/Tagger.java) 
and this variable controls which approach the solution uses at runtime.

```
promote_dlp_other_matches = false
```

### Run Terraform

Continue deployment steps as explained in this doc: [terraform-apply](terraform-4-apply.md)
