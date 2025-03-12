
### Configure DLP Discovery scope

Set the following variables to control which BigQuery tables will be scanned
by DLP.

```terraform

# organization id on which this dlp configuration will reside
dlp_bq_scan_org_id = 0

# folder id to be scanned by the org-level config
dlp_bq_scan_folder_id = 0

# regex for project names to be scanned. Omit to use default that scans all
dlp_bq_project_id_regex = "^project_xyz$"

# regex for dataset names to be scanned. Omit to use default that scans all
dlp_bq_dataset_regex = "^dataset_xyz$"

# regex for table names to be scanned. Omit to use default that scans all
dlp_bq_table_regex = "^table_xyz$"
```

### Configure DLP Discovery Config State

Set to `true` to create the BigQuery discovery config in paused state (e.g. for manual verification, etc)

```terraform
dlp_bq_create_configuration_in_paused_state = false
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

The `promote_dlp_other_matches` setting will determine how the solution picks only one Info Type and policy tag
for columns that have multiple Info Types detected by DLP.


* In case of `true`:    
  The solution will include the `other_matches` that DLP detects for a particular table to promote one policy tag per column. If more than one Info Type is detected (main info type + other matches), "MIXED" policy tag will be applied to that column
* In case of `false`:   
  The solution will only rely on the main info type detected by DLP, or none if DLP is doesn't report one.


Internally, this "promotion" logic is defined by this function: [computeFinalInfo Type](../library/src/main/java/com/google/cloud/pso/bq_pii_classifier/functions/tagger/Tagger.java) 
and this variable controls which approach the solution uses at runtime.

```
promote_dlp_other_matches = false
```

### Run Terraform

Continue deployment steps as explained in this doc: [terraform-apply](terraform-4-apply.md)
