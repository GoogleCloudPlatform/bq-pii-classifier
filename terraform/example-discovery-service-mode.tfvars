
# Check out guide-discovery-service.md on how to use this template

# host project to deploy the solution
project = "example-gcp-project"

# GCP region to deploy the solution's compute resources (e.g. Cloud Run)
compute_region = "europe-west3"

# GCP region to deploy the solution's data resources (e.g. BigQuery datasets, buckets, etc)
data_region = "europe-west3"

# GCP regions for BigQuery datasets to be scanned for PII. Configuring N regions will deploy N policy tag taxonomies, one in each region
source_data_regions    = ["europe-west3", "eu"]

# BigQuery dataset to include solution's resources
bigquery_dataset_name = "bq_pii_classifier"

# BigQuery table to store discovery service results
auto_dlp_results_table_name = "auto_dlp_results"

# Scope of projects, datasets and tables to be scanned for PII
projects_include_list = []
datasets_include_list = ["example-project.example_dataset"]
datasets_exclude_list = []
tables_exclude_list = []

# Set to [FINE_GRAINED_ACCESS_CONTROL] to enforce access control via policy tags. Set to [] otherwise.
data_catalog_taxonomy_activated_policy_types = ["FINE_GRAINED_ACCESS_CONTROL"]

# Example. Set to `[]` of not needed and remove from `classification_taxonomy`. Each custom info type must have a corresponding entry in `classification_taxonomy`
custom_info_types_dictionaries = [
  {
    name       = "CUSTOM_PAYMENT_METHOD"
    likelihood = "LIKELY"
    dictionary = ["Debit Card", "Credit Card"]
  }
]

# Example. Set to `[]` of not needed and remove from `classification_taxonomy`. Each custom info type must have a corresponding entry in `classification_taxonomy`
custom_info_types_regex = [
  {
    name       = "CUSTOM_EMAIL"
    likelihood = "LIKELY"
    regex      = "[A-Z0-9._%+-]+@[A-Z0-9.-]+\\.[A-Z]{2,4}"
  }
]

# PII types to be scanned and their hierarchy and metadata
classification_taxonomy = [
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
  {
    # Example. Remove if needed. Each custom info type must have a corresponding entry here in `classification_taxonomy`
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
    # Example. Remove if needed. Each custom info type must have a corresponding entry here in `classification_taxonomy`
    info_type = "CUSTOM_EMAIL",
    info_type_category = "Custom Regex",
    policy_tag = "custom_email"
    classification = "P2",
    # optional fields
    labels   = [{ key = "contains_custom_pii", value = "true"}],
    inspection_template_number = 1,
    taxonomy_number            = 1
  },
  {
    # Don't remove. Special placeholder for mixed PII types
    info_type = "MIXED",
    info_type_category = "Custom",
    policy_tag = "mixed_pii"
    classification = "P1",
    # optional fields
    labels   = [{ key = "contains_mixed_pii", value = "true"}]
    inspection_template_number = 1,
    taxonomy_number            = 1
  },
]

# To segregate access of columns tagged as PII that belongs to multiple functional areas. You can use one or more domains.
domain_mapping = [
  {
    project = "example_data_project_1",
    domain = "example_domain_a",
    datasets = [] // leave empty if no dataset overrides is required for this project
  },
  {
    project = "example_data_project_1",
    domain = "example_domain_a",
    datasets = [
      {
        name = "example_dataset_1",
        domain = "example_domain_b"
      },
    ]
  }
]

# Defining who should have access to columns tagged as PII in each functional area (i.e. domains) and PII group (i.e. classification)
# For each domain defined in `domain_mapping`, there should be an key in this map. E.g. "domain_1"
# For each `classification` defined in `classification_taxonomy` there should be a value for that key. E.g. "P1", "P2", etc
iam_mapping = {
  example_domain_a = {
    P1 = ["user:example-user@example.com", "group:example-group@example.com", "serviceAccount:example-sa@example.com"],
    P2 = ["user:example-user@example.com", "group:example-group@example.com", "serviceAccount:example-sa@example.com"]
  },
  example_domain_b = {
    P1 = ["user:example-user@example.com", "group:example-group@example.com", "serviceAccount:example-sa@example.com"],
    P2 = ["user:example-user@example.com", "group:example-group@example.com", "serviceAccount:example-sa@example.com"]
  },
}

# To attach policy tags to columns or not. is_dry_run_tags = False means to attach policy tags
is_dry_run_tags = "False"

# To attach resource labels to BigQuery tables or not. is_dry_run_labels = False means to attach labels
is_dry_run_labels = "False"

# Terraform service account name used to deploy this Terraform module
terraform_service_account = "bq-pii-classifier-terraform"

# To use discovery service mode or not
is_auto_dlp_mode = true

# Names and tags for container images use by Cloud Run
tagging_dispatcher_service_image = "bqsc-tagging-dispatcher-service:latest"
tagger_service_image = "bqsc-tagger-service:latest"


# CRON expression for Cloud Scheduler. How often to tag all tables in the configured scan scope based on Auto-DLP results
tagging_cron_expression = "0 12 1 * *"

# Set to true to prevent Terraform from deleting BigQuery dataset and GCS buckets without alert (recommended for production usage or when DLP cost is high and you like to retain the scan results)
terraform_data_deletion_protection = true










