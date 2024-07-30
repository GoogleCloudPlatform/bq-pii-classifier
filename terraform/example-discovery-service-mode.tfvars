
# Check out guide-discovery-service.md on how to use this template

project        = ""
compute_region = ""
data_region    = ""

bigquery_dataset_name = "bq_security_classifier"

tables_include_list   = []
datasets_include_list = []
projects_include_list = []
datasets_exclude_list = []
tables_exclude_list   = []

# Set to [FINE_GRAINED_ACCESS_CONTROL] to enforce access control via policy tags. Set to [] otherwise.
data_catalog_taxonomy_activated_policy_types = ["FINE_GRAINED_ACCESS_CONTROL"]

classification_taxonomy = [
  {
    info_type = "",
    info_type_category = "",
    policy_tag = "",
    classification = ""
  },
  # Keep this placeholder info type for mixed info types
  {
    info_type                  = "MIXED",
    info_type_category         = "Custom",
    policy_tag                 = "mixed_pii",
    classification             = "<set classification level>"
  },

]

domain_mapping = [
  {
    project = "",
    domain = "",
    datasets = [] // leave empty if no dataset overrides is required for this project
  },
  {
    project = "",
    domain = "",
    datasets = [
      {
        name = "",
        domain = ""
      },
    ]
  }
]

# For each domain defined in `domain_mapping`, there should be an key in this map. E.g. "domain_1"
# For each `classification` defined in `classification_taxonomy` there should be a value for that key. E.g. "P1", "P2", etc
iam_mapping = {
  domain_1 = {
    P1 = ["<IAM principles who should have access to columns with policy tags under this classification level, in that domain >"],
    P2 = []
  },
}

# Set the scan limits based on intervals
table_scan_limits_json_config = {
  limitType : "NUMBER_OF_ROWS",
  limits : {
    "10000" : "10",
    "100000" : "100",
    "1000000" : "1000"
  }
}

is_dry_run = "False"

dlp_service_account =  "service-<PROJECT_NUMBER>@dlp-api.iam.gserviceaccount.com"

cloud_scheduler_account = "service-<PROJECT_NUMBER>@gcp-sa-cloudscheduler.iam.gserviceaccount.com"

terraform_service_account = "bq-pii-classifier-terraform@<PROJECT_ID>.iam.gserviceaccount.com"

is_auto_dlp_mode = true

tagging_dispatcher_service_image    = ""

tagger_service_image                = ""

tagging_cron_expression    = "0 0 1 * *"


