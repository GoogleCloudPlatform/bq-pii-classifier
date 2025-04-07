
### Configure DLP Discovery scope

Set the following variables to control which GCS Buckets will be scanned
by DLP.

```terraform
# folder id to be scanned by the org-level config
dlp_gcs_scan_folder_id_list = [0]

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

### Configure tags

Set the following variable to `true` to let DLP discovery service attach sensitivity levels tags to buckets

```terraform
dlp_gcs_apply_tags = true
```

In needed, the default names for the sensitivity tag key and values could be overridden via: 
```terraform
dlp_tag_sensitivity_level_key_name = "dlp_sensitivity_level"
dlp_tag_high_sensitivity_value_name = "high"
dlp_tag_moderate_sensitivity_value_name = "moderate"
dlp_tag_low_sensitivity_value_name = "low"
```

### Run Terraform

Continue deployment steps as explained in this doc: [terraform-apply](terraform-4-apply.md)