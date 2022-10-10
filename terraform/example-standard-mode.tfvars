
# Check out guide-standard-dlp.md on how to use this template
project = ""
compute_region = ""
data_region = ""

bigquery_dataset_name = "bq_security_classifier"

tables_include_list = []
datasets_include_list = []
projects_include_list = []
datasets_exclude_list = []
tables_exclude_list = []

data_catalog_taxonomy_activated_policy_types = ["FINE_GRAINED_ACCESS_CONTROL"]

classification_taxonomy = [
  {
    info_type = "",
    info_type_category = "",
    policy_tag = "",
    classification = ""
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


iam_mapping = {

  domain_1 = {
    P1 = [],
    P2 = []
  },

}

is_dry_run = "False"

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

table_scan_limits_json_config = {
  limitType: "NUMBER_OF_ROWS",
  limits: {
    "10000":"10",
    "100000":"100",
    "1000000":"1000"
  }
}

promote_mixed_info_types = false

