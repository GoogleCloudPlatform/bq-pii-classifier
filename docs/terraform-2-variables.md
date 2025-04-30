
### Create a Terraform `.tfvars` file

Create a new `.tfvars` file and override the variables in the below sections. You can use one of the example
`.tfavrs` files as a base on the stack you want to deploy
* [Example Variables for BigQuery Stack](../terraform/example_variables_for_bq_stack.tfvars)
* [Example Variables for GCS Stack](../terraform/example_variables_for_gcs_stack.tfvars)

```shell
export VARS=my-variables.tfvars
```

Alternatively, you can merge both example files to deploy both stacks.

### Configure Terraform Variables

Most variables (e.g. service accounts names, services names, etc) have default values defined in `variables-xx` files such as [variables.tf](/terraform/variables.tf).

You can use the defaults or overwrite them in the `.tfvars` file you just created.

However, you must define the below variables:

```terraform
project = "<GCP project ID to deploy solution to>"
org_id = 0 # < organization id in which the dlp configurations will be created >
compute_region = "<GCP region to deploy compute resources e.g. cloud run, iam, etc>"
data_region = "<GCP region where application-owned data will be deployed e.g. dlp results table, gcs buckets, etc. >"
source_data_regions  = ["<List of GCP regions where the source data resides. Policy tags and DLP inspection templates will be deployed there.>"]
```

### Configure Terraform Service Account

Use the service account email that was created for Terraform in a previous step.

```terraform
terraform_service_account_email = "bq-pii-classifier-terraform@<PROJECT ID>.iam.gserviceaccount.com"
```

### Configure Custom Info Types (Optional)

One could define custom Info Types to be used by DLP for inspecting data assets. Supported
Info Types are dictionaries and/or regular expressions.

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

`likelihood` is the matching likelihood to return for this Custom Info Type and could be any of the following values `[VERY_UNLIKELY, UNLIKELY, POSSIBLE, LIKELY, VERY_LIKELY]`

If no custom Info Types are required, omit these variables


### Configure Data Classification Taxonomy

A mapping between DLP Info Types (Standard and Custom), policy tags and classifications. Classifications are parent nodes in the taxonomy to group children nodes.

```terraform

classification_taxonomy = [
  # example for built-in info types
  {
    info_type = "EMAIL_ADDRESS",
    info_type_category = "Standard",
    policy_tag = "email",
    classification = "P1",
    # optional fields
    labels   = [{ key = "contains_email_pii", value = "true"}],
    inspection_template_number = 1,
    taxonomy_number            = 1
  },
  {
    info_type = "PHONE_NUMBER",
    info_type_category = "Standard",
    policy_tag = "phone"
    classification = "P2",
    # optional fields
    labels   = [{ key = "contains_phones_pii", value = "true"}],
    inspection_template_number = 1,
    taxonomy_number            = 1
  },
  # example for custom info types (created in previous variables)
  {
    info_type = "CUSTOM_PAYMENT_METHOD",
    info_type_category = "Custom Dictionary",
    policy_tag = "payment_method"
    classification = "P1",
    # optional fields
    labels   = [{ key = "contains_custom_pii", value = "true"}],
    inspection_template_number = 1,
    taxonomy_number            = 1
  },
  {
    info_type = "CUSTOM_EMAIL",
    info_type_category = "Custom Regex",
    policy_tag = "custom_email"
    classification = "P2",
    # optional fields
    labels   = [{ key = "contains_custom_pii", value = "true"}],
    inspection_template_number = 1,
    taxonomy_number            = 1
  },
  # special place holder for fields with multiple info types detected by DLP
  {
    info_type = "MIXED",
    info_type_category = "Custom",
    policy_tag = "mixed_pii"
    classification = "P1",
    # optional fields
    labels   = [{ key = "contains_mixed_pii", value = "true"}]
    inspection_template_number = 1,
    taxonomy_number            = 1
  },

  .. etc
  ]
```
This will enable the solution to:
* Build hierarchical policy tag taxonomies
* To identify which policy tag to apply to a column based on the Info Type discovered


| Field                        | Required  | Description                                                                          |
|------------------------------|-----------|--------------------------------------------------------------------------------------|
| `classifications`            | Yes| are parent nodes in the taxonomy to group children nodes.                            |
| `info_type_category`         | Yes| is either "standard" or "custom".                                                    |
| `labels`                     | No | list of resource labels to be applied to tables where a certain PII is detected      |
| `inspection_template_number` | No | to deploy N DLP inspection templates for scalability. Explained in the next section  |
| `taxonomy_number`            | No | to deploy N policy tag taxonomies for scalability. Explained in the next section     |



#### Dealing with Info Type Count Limitation

There are two GCP limits that one could hit in defining taxonomies:
* Max number of elements in a single taxonomy is 100 (including parent and children nodes)
* Max number of custom Info Types per inspection template is 30

in order to get around those, the solution might need to deploy more than 1 taxonomy and/or more than 1 DLP inspection
template. For that, the optional `inspection_template_number` and `taxonomy_number` fields are used:
* `inspection_template_number` default value is `1`. It means that this particular Info Type will be created in the Nth inspection template.
  This is needed if more than 30 custom Info Types are required, otherwise use `1`. Please note that if more than one inspection template
  is required, each table will be scanned N times, one per each inspection template.
* `taxonomy_number` default value is `1`. It means that this particular Policy Tag will be created in the Nth Cloud Data Catalog Taxonomy.
  This is needed of more than 100 nodes are to be created, otherwise use `1`. For a better visibility, try to locate all nodes
  under one parent (i.e. classification) in the same taxonomy.

#### Dealing with Mixed PII:

DLP might find that one field contains multiple Info Types (e.g. free text fields). Since
we can only assign one policy tag to a column we need to have a special placeholder for such fields.  
This placeholder is yet another entry in the classification taxonomy with info_type = "MIXED".
Users can configure the policy tag name and classification level associated to it, but the info_type can't be changed.
This "MIXED" Info Type is a special flag used by the solution and not a standard or custom DLP Info Type.

```terraform
  {
    info_type = "MIXED",
    info_type_category = "Custom",
    policy_tag = "mixed_pii"
    classification = "P1",
    # optional fields
    labels   = [{ key = "contains_mixed_pii", value = "true"}]
    inspection_template_number = 1,
    taxonomy_number            = 1
  }
```

### Configure DLP global template

DLP inspection templates are deployed to all `source_data_regions` by default.
Set this to true to add the `global` region to the list to be used to inspect resources in any region if you're not sure 
where the data is in your org or to reduce the number of templates.

```terraform
deploy_dlp_inspection_template_to_global_region = true
```

### Configure DryRun labels options

By setting `is_dry_run_labels = true` the solution will not attach the configured resource labels in
`classification_taxonomy` to the inspected resources and will only write log messages that can be monitored via the
`v_log_label_history` and `v_log_label_history_gcs` BigQuery view.


```terraform
is_dry_run_labels = false
```



### Configure Cloud Run Service Image

Earlier, we built a  container image that will be used by services of this solution.

In this step, we instruct Terraform to use that image in the Cloud Run services
that it will create.

PS: Terraform will just "link" a Cloud Run to an existing image. It will not build the images from the code base (this
is already done in a previous step)

```terraform
image_name = "annotations-services:latest"
``` 

### Configure data deletion protection

Set to true in a prod env or when DLP costs are high to retain the scan results and
avoid accidental deletion by terraform apply

```terraform
terraform_data_deletion_protection = true
```


### Configure deployment stacks

Choose which DLP discovery configurations to deploy: `BIGQUERY_DISCOVERY` and/or `GCS_DISCOVERY`

```terraform
supported_stacks = ["BIGQUERY_DISCOVERY", "GCS_DISCOVERY"]
```

For each chosen stack, continue Terraform configuration via these guides
* [BigQuery Stack Variables](./terraform-2a-bq-discovery-variables.md)
* [GCS  Stack Variables](./terraform-2b-gcs-discovery-variables.md)