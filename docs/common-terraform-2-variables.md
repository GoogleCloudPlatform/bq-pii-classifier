### Create a Terraform `.tfvars` file

Create a new `.tfvars` file and override the variables in the below sections. You can use one of the example
`.tfavrs` files as a base ([example-standard-mode](../terraform/example-standard-mode.tfvars), [example-discovery-service-mode](../terraform/example-discovery-service-mode.tfvars)). 

```
export VARS=my-variables.tfvars
```

### Configure Basic Variables

Most required variables have default names defined in [variables.tf](../terraform/variables.tf).
You can use the defaults or overwrite them in the `.tfvars` file you just created.

Both ways, you must define the below variables:

```
project = "<GCP project ID to deploy solution to>"
compute_region = "<GCP region to deploy compute resources e.g. cloud run, iam, etc>"
data_region = "<GCP region where the target data resides and where data-related resources will be deployed e.g. data calatog taxonomies, dlp template, bigquery dataset, etc>"
```

### Configure BigQuery Dataset  

This dataset will be created under the data_region and will
hold all solution-managed tables and config views. Optionally, it could 
be used to store discovery service findings (configured outside of Terraform)

```
bigquery_dataset_name = "<>"
```

### Configure Scanning Scope

Set the following variables to define the BigQuery scope used by the entry point Cloud Scheduler.

At least one variable should be provided among the _INCLUDE configs.

tables format: ["project.dataset.table1", "project.dataset.table2", etc]
datasets format: ["project.dataset", "project.dataset", etc]
projects format: ["project1", "project2", etc]

```
tables_include_list = []
datasets_include_list = []
projects_include_list = []
datasets_exclude_list = []
tables_exclude_list = []
```

### Configure Custom Info Types

One could define custom InfoTypes to be used by DLP for inspecting tables. Supported
InfoTypes could be dictionaries or regular expressions.  

Dictionaries are defined as follows:
```
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
```
custom_info_types_regex = [
  {
    name       = "CUSTOM_EMAIL"
    likelihood = "LIKELY"
    regex      = "[A-Z0-9._%+-]+@[A-Z0-9.-]+\\.[A-Z]{2,4}"
  }
]
```

`likelihood` is matching likelihood to return for this CustomInfoType and could be any of the following values `[VERY_UNLIKELY, UNLIKELY, POSSIBLE, LIKELY, VERY_LIKELY]`

PS: If no custom InfoTypes are required use empty lists for the variables (e.g. `custom_info_types_regex = []` ) 


### Configure Data Classification Taxonomy

A mapping between DLP InfoTypes (Standard and Custom), policy tags and classifications.  
Classifications: are parent nodes in the taxonomy to group children nodes.

`classifications`: are parent nodes in the taxonomy to group children nodes.  
`info_type_category`: is either "standard" or "custom".
`labels `: is an optional list of resource labels to be applied to tables where a certain PII is detected. Set to `[]`

This will enable the solution to:
 * Build hierarchical policy tag taxonomies
 * To identify which policy tag to apply to a column based on the PII/InfoType discovered

#### Dealing with Mixed PII:  
DLP might find that one field contains multiple InfoTypes (e.g. free text fields). Since
we can only assign one policy tag to a column we need to have a special placeholder for such fields.  
This placeholder is yet another entry in the classification taxonomy with info_type = "MIXED". 
Users can configure the policy tag name and classification level associated to it, but the info_type can't be changed.
This "MIXED" InfoType is a special flag used by the solution and not a standard or custom DLP InfoType.

#### Dealing with InfoType Count Limitation
There are two GCP limits that one could hit in defining taxonomies:
* Max number of elements in a single taxonomy is 100 (including parent and children nodes)
* Max number of custom InfoTypes per inspection template is 30

in order to get around those, the solution might need to deploy more than 1 taxonomy and/or more than 1 DLP inspection
template. For that, `inspection_template_number` and `taxonomy_number` are used:
* `inspection_template_number` is a value starting from `1`. It means that this particular InfoType will be created in the Nth inspection template.
   This is needed if more than 30 custom InfoTypes are required, otherwise use `1`. Please note that if more than one inspection template 
   is required, each table will be scanned N times, one per each inspection template.
* `taxonomy_number` is a value starting from `1`. It means that this particular Policy Tag will be created in the Nth Cloud Data Catalog Taxonomy.
   This is needed of more than 100 nodes are to be created, otherwise use `1`. For a better visibility, try to locate all nodes
   under one parent (i.e. classification) in the same taxonomy.
```

classification_taxonomy = [
  {
    info_type = "EMAIL_ADDRESS",
    info_type_category = "Standard",
    policy_tag = "email",
    classification = "P1",
    labels   = [{ key = "contains_email_pii", value = "true"}],
    inspection_template_number = 1,
    taxonomy_number            = 1
  },
  {
    info_type = "PHONE_NUMBER",
    info_type_category = Standard",
    policy_tag = "phone"
    classification = "P2",
    labels   = [{ key = "contains_phones_pii", value = "true"}],
    inspection_template_number = 1,
    taxonomy_number            = 1
  },
  {
    info_type = "CUSTOM_PAYMENT_METHOD",
    info_type_category = Custom Dictionary",
    policy_tag = "payment_method"
    classification = "P1",
    labels   = [],
    inspection_template_number = 1,
    taxonomy_number            = 1
  },
  {
    info_type = "CUSTOM_EMAIL",
    info_type_category = Custom Regex",
    policy_tag = "custom_email"
    classification = "P2",
    labels   = [],
    inspection_template_number = 1,
    taxonomy_number            = 1
  },
  {
    info_type = "MIXED",
    info_type_category = "Custom",
    policy_tag = "mixed_pii"
    classification = "P1",
    labels   = [{ key = "contains_mixed_pii", value = "true"}]
    inspection_template_number = 1,
    taxonomy_number            = 1
  },

  .. etc
  ]
```

### Configure Domain Mapping

A one-to-one mapping between GCP projects and/or BigQuery datasets and domains.
Domains are logical groupings that determine access control boundaries. For example, if  “Marketing” and “Finance” are domains this means that marketing PII readers can only read their PII data but can’t read finance PII data.

For each configured “domain” a corresponding taxonomy will be generated in Cloud Data Catalog. Each taxonomy will contain the policy tags defined in InfoType - Policy Tag Mapping in the hierarchy defined in Terraform (adjustable)

You can define one domain per project that will be applied to all
BigQuery tables inside it. Additionally, you can overwrite this default project 
domain on dataset level (e.g. in case of a DWH project having data from different domains).


```
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
### Configure domain-IAM mapping

A mapping between domains/classifications and IAM users and/or groups. 
This will determine who has access to PII data under each domain and classification.

This is a dictionary of dictionaries. The first dict has in the format "<domain> = dict" 
while the second level of dicts are in the format of "<classification> = [list of IAM members]". Both the "<domain>" and "<classification>"
are the ones configured in `domain_mapping`.  

For users: "user:username@example.com"
For groups: "group:groupname@example.com"  

For example:  

```
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

### Configure DryRun options

By setting `is_dry_run_tags = "True"` the solution will not attach the configured policy tags in
`classification_taxonomy` to BigQuery columns and will only write log messages that can be monitored via the
`v_log_tag_history` monitoring view


Also, by setting `is_dry_run_labels = "True"` the solution will not add the configured resource labels in 
`classification_taxonomy` to BigQuery tables and will only write log messages that can be monitored via the 
`v_log_label_history` monitoring view

Add the following variables in the `.tfvars` file:
```
is_dry_run_tags = "False"
is_dry_run_labels = "False"
```

### Configure DLP Service Account

DLP service account must have a set of permissions on the resources created by the solution.

Steps:
 * Detect the DLP service account in the host project
     * DLP service account is in the form service-<project number>@dlp-api.iam.gserviceaccount.com
     * Search in IAM for @dlp-api.iam.gserviceaccount.com (tick the "Include Google-Provided role grants" box)
     * If this host project never used DLP before, run a sample inspection job for GCP to create a service account
 * Set the `dlp_service_account` variable in the Terraform variables file

```
dlp_service_account = "service-<project number>@dlp-api.iam.gserviceaccount.com"

```

PS: project number is different from project id/name. You can find both info on the home page of any project.

### Configure Cloud Scheduler Service Account

We will need to grant the Cloud Scheduler account permissions to use parts of the solution 

```
cloud_scheduler_account = "service-<project number>@gcp-sa-cloudscheduler.iam.gserviceaccount.com"
```

### Configure Terraform Service Account

Terraform needs to run with a service account to deploy DLP resources. User accounts are not enough.  

This service account is created in a previous step of the deployment. Use the full email of the created account.
```
terraform_service_account = "bq-pii-classifier-terraform@<host project>.iam.gserviceaccount.com"
```


