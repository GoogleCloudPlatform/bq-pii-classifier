
# Check out guide-auto-dlp.md on how to use this template

project = ""
compute_region = ""
data_region = ""

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

is_auto_dlp_mode = true

tagging_dispatcher_service_image = ""
tagger_service_image = ""

bigquery_dataset_name = ""

auto_dlp_results_table_name = "auto_dlp_results"

tagging_cron_expression = ""