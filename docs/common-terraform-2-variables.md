### Create a Terraform .tfvars file

Create a new .tfvars file and override the variables in the below sections. You can use one of the example
tfavrs files as a base ([example-standard-mode](terraform/example-standard-mode.tfvars), [example-auto-dlp-mode](terraform/example-auto-dlp-mode.tfvars)). 

```
export VARS=my-variables.tfvars
```

### Configure Basic Variables

Most required variables have default names defined in [variables.tf](terraform/variables.tf).
You can use the defaults or overwrite them in the .tfvars file you just created.

Both ways, you must define the below variables:

```
project = "<GCP project ID to deploy solution to>"
compute_region = "<GCP region to deploy compute resources e.g. cloud run, iam, etc>"
data_region = "<GCP region where the target data resides and where data-related resources will be deployed e.g. data calatog taxonomies, dlp template, bigquery dataset, etc>"
env = "<dev, tst, prod, poc, etc>"
```

PS: the `env` value will be added as a suffix to most resources

### Configure BigQuery Dataset  

This dataset will be created under the data_region and will
hold all solution-managed tables and config views. Optionally, it could 
be used to store Auto DLP findings (configured outside of Terraform)

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
### Configure Data Classification Taxonomy

A mapping between DLP InfoTypes, policy tags and classifications.  
Classifications: are parent nodes in the taxonomy to group children nodes.  
info_type_category: is either "standard" or "custom".  Standard types will
be automatically added the DLP inspection template while Custom types 
have to be manually configured in Terraform.

This will enable the solution:
 * Build hierarchical policy tag taxonomies
 * To identify which policy tag to apply to a column based on the PII/InfoType discovered

PS: Custom INFO_TYPEs configured in the [DLP inspection job](terraform/modules/dlp/main.tf) 
MUST be mapped here. Otherwise, mapping to policy tag ids will fail.  

Dealing with Mixed PII:  
DLP might find that one field contains multiple InfoTypes (e.g. free text fields). Since
we can only assign one policy tag to a column we need to have a special placeholder for 
such fields.  
This placeholder is yet another entry in the classification taxonomy with info_type = "MIXED". 
Users can configure the policy tag name and classification level associated to it, but the info_type can't be changed.
This "MIXED" InfoType is a special flag used by the solution and not a standard or custom DLP InfoType.

```

classification_taxonomy = [
  {
    info_type = "EMAIL_ADDRESS",
    info_type_category = "standard",
    policy_tag = "email",
    classification = "P1"
  },
  {
    info_type = "PHONE_NUMBER",
    info_type_category = "standard",
    policy_tag = "phone"
    classification = "P2"
  },
  {
    info_type = "MIXED",
    info_type_category = "custom",
    policy_tag = "mixed_pii"
    classification = "P1"
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
    High = ["user:marketing-p1-reader@example.com"],
    Low = ["user:marketing-p2-reader@example.com"]
  },

  finance = {
    High = ["user:finance-p1-reader@example.com"],
    Low = ["user:finance-p2-reader@example.com"]
  },

  dwh = {
    P1 = ["user:dwh-p1-reader@example.com"],
    P2 = ["user:dwh-p2-reader@example.com"]
  }
}

```

### Configure DryRun

By setting `is_dry_run = "True"` the solution will scan BigQuery tables 
for PII data, store the scan result, but it will not apply policy tags to columns.
Instead, the "Tagger" function will only log [actions](functions/bq_security_classifier_functions/src/main/java/com/google/cloud/pso/bq_security_classifier/functions/tagger/ColumnTaggingAction.java).

Check the Monitoring sections on how to access these logs.  

```
is_dry_run = "False"
```

### Configure DLP Service Account

* DLP service account must have Fine-Grained Reader role on the created taxonomies in order to inspect tagged columns for new data.
Steps:
 * Detect the DLP service account in the host project
     * DLP service account is in the form service-<project number>@dlp-api.iam.gserviceaccount.com
     * Search in IAM for @dlp-api.iam.gserviceaccount.com (tick the "Include Google-Provided role grants" box)
     * If this host project never used DLP before, run a sample inspection job for GCP to create a service account
 * Set the `dlp_service_account` variable in the terraform variables file

```
dlp_service_account = "service-<project number>@dlp-api.iam.gserviceaccount.com"

```

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


