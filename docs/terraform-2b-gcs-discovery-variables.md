
### Configure DLP Discovery scope

Set the following variables to control which GCS Buckets will be scanned
by DLP.

```terraform
# org id to deploy the dlp discovery config to
dlp_gcs_scan_org_id = 0

# folder id to be scanned by the org-level config
dlp_gcs_scan_folder_id = 0

# regex for project names to be scanned. Omit to use default that scans all
dlp_gcs_project_id_regex = "^project_xyz$"

# regex for bucket names to be scanned. Omit to use default that scans all
dlp_gcs_bucket_name_regex = "^bucket_xyz$"
```

### Configure DLP Discovery Config State

Set to `true` to create the GCS discovery config in paused state (e.g. for manual verification, etc)

```terraform
dlp_gcs_create_configuration_in_paused_state = false
```

### Configure overwriting labels

Set to a regex to be used to identify and delete/overwrite existing GCS buckets resource labels that are previously created by the solution.
This behaviour is useful when the latest DLP findings doesn't include previously assigned labels anymore due o change in configuration or change in underlying data.

Alternatively, Omit the variable to use its default value that doesn't delete any existing labels.

```terraform
gcs_existing_labels_regex = "^contains_"
```

Recommended to omit this variable in early runs to avoid overwriting any existing labels by mistake.

### Run Terraform

Continue deployment steps as explained in this doc: [terraform-apply](terraform-4-apply.md)