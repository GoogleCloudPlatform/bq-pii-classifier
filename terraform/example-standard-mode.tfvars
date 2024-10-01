
# Check out guide-standard-dlp.md on how to use this template

project = ""
compute_region = ""
data_region = ""
source_data_regions    = []

bigquery_dataset_name = "bq_security_classifier"

datasets_include_list = []
projects_include_list = []
datasets_exclude_list = []
tables_exclude_list = []

# Set to [FINE_GRAINED_ACCESS_CONTROL] to enforce access control via policy tags. Set to [] otherwise.
data_catalog_taxonomy_activated_policy_types = ["FINE_GRAINED_ACCESS_CONTROL"]

custom_info_types_dictionaries = [
  {
    name       = ""
    likelihood = ""
    dictionary = []
  }
]

custom_info_types_regex = [
  {
    name       = ""
    likelihood = ""
    regex      = ""
  }
]

classification_taxonomy = [
  {
    info_type = "",
    info_type_category = "",
    policy_tag = "",
    classification = "EXAMPLE_PII_LEVEL_1",
    labels = [],
    inspection_template_number = 1,
    taxonomy_number            = 1
  },
  # Keep this placeholder info type for mixed info types and change the classification
  {
    info_type                  = "MIXED",
    info_type_category         = "Custom",
    policy_tag                 = "mixed_pii",
    classification             = "EXAMPLE_PII_LEVEL_2",
    labels = [],
    inspection_template_number = 1,
    taxonomy_number            = 1
  },

]

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

# For each domain defined in `domain_mapping`, there should be an key in this map. E.g. "domain_1"
# For each `classification` defined in `classification_taxonomy` there should be a value for that key. E.g. "P1", "P2", etc
iam_mapping = {
  example_domain_a = {
    EXAMPLE_PII_LEVEL_1 = ["<IAM principles who should have access to columns with policy tags under this classification level, in that domain >"],
    EXAMPLE_PII_LEVEL_2 = ["<IAM principles who should have access to columns with policy tags under this classification level, in that domain >"]
  },
  example_domain_b = {
    EXAMPLE_PII_LEVEL_1 = ["<IAM principles who should have access to columns with policy tags under this classification level, in that domain >"],
    EXAMPLE_PII_LEVEL_2 = ["<IAM principles who should have access to columns with policy tags under this classification level, in that domain >"]
  },
}

is_dry_run_tags = "False"

is_dry_run_labels = "False"

dlp_service_account =  "service-<PROJECT_NUMBER>@dlp-api.iam.gserviceaccount.com"

cloud_scheduler_account = "service-<PROJECT_NUMBER>@gcp-sa-cloudscheduler.iam.gserviceaccount.com"

terraform_service_account = "bq-pii-classifier-terraform@<PROJECT_ID>.iam.gserviceaccount.com"

is_auto_dlp_mode = false

tagging_dispatcher_service_image = ""
inspection_dispatcher_service_image = ""
inspector_service_image = ""
tagger_service_image = ""

inspection_cron_expression = ""
tagging_cron_expression = ""

# Set the scan limits based on intervals
table_scan_limits_json_config = {
  limitType: "NUMBER_OF_ROWS",
  limits: {
    "10000":"100",
    "100000":"1000",
    "1000000":"10000"
  }
}

promote_mixed_info_types = false

