
###################### Common Variables ################################################

# Terraform service account name used to deploy this Terraform module
terraform_service_account_email = "bq-pii-classifier-terraform@<PROJECT ID>.iam.gserviceaccount.com"

# container image name that contains the services code (i.e. tagging dispatcher & tagger)
# this is built and deployed outside of TF in an earlier step
image_name = "bq-pii-classifier-services:latest"

# host project to deploy the solution
application_project = ""

# org id to deploy the dlp discovery config to
org_id = 0

# GCP region to deploy the solution's compute resources (e.g. Cloud Run)
compute_region = ""

# GCP region to deploy the solution's data resources (e.g. BigQuery datasets, buckets, etc)
data_region = ""

# GCP regions for BigQuery datasets to be scanned for PII. Configuring N regions will deploy N policy tag taxonomies, one in each region
source_data_regions    = ["", ""]

# BigQuery dataset to include solution's resources
bigquery_dataset_name = "bq_pii_classifier"

# Example. Set to `[]` of not needed and remove from `classification_taxonomy`. Each custom info type must have a corresponding entry in `classification_taxonomy`
custom_info_types_dictionaries = []
#  {
#    name       = "CUSTOM_PAYMENT_METHOD"
#    likelihood = "LIKELY"
#    dictionary = ["Debit Card", "Credit Card"]
#  }


# Example. Set to `[]` of not needed and remove from `classification_taxonomy`. Each custom info type must have a corresponding entry in `classification_taxonomy`
custom_info_types_regex = []
#  {
#    name       = "CUSTOM_EMAIL"
#    likelihood = "LIKELY"
#    regex      = "[A-Z0-9._%+-]+@[A-Z0-9.-]+\\.[A-Z]{2,4}"
#  }


# Info Types to be scanned and their hierarchy and metadata
classification_taxonomy = [

  { info_type = "STREET_ADDRESS",
    info_type_category = "Standard",
    policy_tag = "street_address",
    classification = "Location",
    labels = [{ key = "contains_location_data", value = "yes"}]},
  { info_type = "EMAIL_ADDRESS",
    info_type_category = "Standard",
    policy_tag = "email_address",
    classification = "PII",
    labels = [{ key = "contains_pii_data", value = "yes"}],
  },

  # Mixed - This is a special placeholder for fields with multiple info types detected
  {
    info_type          = "MIXED",
    info_type_category = "Custom",
    policy_tag         = "mixed_pii",
    classification     = "Other",
    labels             = [{ key = "dg_data_category_mixed", value = "yes"}],
    inspection_template_number = 1,
    taxonomy_number            = 1
  },
]

# Names and tags for container images use by Cloud Run
gar_docker_repo_name = "docker-repo"

# change to true in a prod env or where DLP costs are high to retain the scan results
terraform_data_deletion_protection = true

# To attach resource labels to BigQuery tables and GCS buckets. is_dry_run_labels = False means to attach labels
is_dry_run_labels = false

# dlp inspection templates are deployed to all source_data_regions []. Set this to true to add the `global` region
# to be used to scan resources in all regions (if you're org policy allows global data residency)
deploy_dlp_inspection_template_to_global_region = true

###################### GCS Stack Variables ################################################

dlp_gcs_discovery_configurations = [
  {
    # folder id to be scanned by the org-level config
    folder_id = 1234

    # regex for project names to be scanned. Remove to use default that scans all
    project_id_regex = "^project_xyz$"

    # regex for bucket names to be scanned. Remove to use default that scans all
    bucket_name_regex = "^bucket_xyz$"

    # Set to true to create the config in paused state (e.g. for manual verification, etc)
    create_configuration_in_paused_state = false
  },
  {
    folder_id = 5678
  }
]

# Used to identify and delete existing GCS resource labels previously created by the solution when new DLP findings doesn't include that label
# remove to use default value that doesn't delete any existing labels
gcs_existing_labels_regex = "^contains_"

