from dotenv import load_dotenv
import os
from pulumi.config import Config

def get_env(name, default):
    var = os.getenv(name)
    return var if var else default

config = Config()

project_id = config.get("project_id") # get_env("PROJECT_ID","a208571-phamilton-sandbox")
compute_region = config.get("compute-region") #get_env("COMPUTE_REGION","us-east1")
data_region = config.get("data-region") #get_env("DATA_REGION","us-east4")
domain = config.get("domain") #get_env("DOMAIN","datalake")
project_number = config.get("project-number") #get_env("PROJECT_NUMBER","816938506328")

bigquery_dataset_name = config.get("dlp-dataset-name") #get_env("DLP_DATASET_NAME","bq_security_classifier")
gcs_flags_bucket_name = config.get("gcs-flags-bucket-name") #get_env("GCS_FLAGS_BUCKET_NAME","bq-pii-classifier-flags")
docker_repo = config.get("docker-repo") #get_env("DOCKER_REPO","gcr.io")

assetId = 'a208571'

tables_include_list = []
datasets_include_list = []
projects_include_list = [project_id]
datasets_exclude_list = []
tables_exclude_list = []


data_catalog_taxonomy_activated_policy_types = ["FINE_GRAINED_ACCESS_CONTROL"]

classification_taxonomy = [
  {
    "info_type" : "SWIFT_CODE",
    "info_type_category" : "standard",
    "policy_tag" : "show-code",
    "classification" : "EXE",
  },
  {
    "info_type" : "EMAIL_ADDRESS",
    "info_type_category" : "standard",
    "policy_tag" : "hide-email",
    "classification" :"EMP",
  },
  {
    "info_type" : "STREET_ADDRESS",
    "info_type_category" : "standard",
    "policy_tag" : "hide-address",
    "classification" : "EMP",
  },
  {
    "info_type" :"US_SOCIAL_SECURITY_NUMBER",
    "info_type_category" :"standard",
    "policy_tag" :"show-ssn",
    "classification" :"EXE"
  },
   {
    "info_type" :"PHONE_NUMBER",
    "info_type_category" :"standard",
    "policy_tag" :"hide-text",
    "classification" :"EMP"
  }
]


domain_mapping = [
  {
    "project" : project_id,
    "domain" : domain,
    "datasets" : [] # leave empty if no dataset overrides is required for this project
  },
]


iam_mapping = {
  domain : {
    "EMP" : ["user:maharshi.dave@thomsonreuters.com","user:alexis.suarez@thomsonreuters.com","user:solomon.shorser@thomsonreuters.com"],
    "EXE" : ["user:peter.hamilton@thomsonreuters.com","user:nestor.mejia@thomsonreuters.com"]
  },

}

is_dry_run = False

dlp_service_account =  f"service-{project_number}@dlp-api.iam.gserviceaccount.com"

cloud_scheduler_account = f"service-{project_number}@gcp-sa-cloudscheduler.iam.gserviceaccount.com"

terraform_service_account = f"bq-pii-classifier-terraform@{project_id}.iam.gserviceaccount.com"

is_auto_dlp_mode = False

tagging_dispatcher_service_image = f"{compute_region}-docker.pkg.dev/{project_id}/{docker_repo}/bqsc-tagging-dispatcher-service:latest"
inspection_dispatcher_service_image = f"{compute_region}-docker.pkg.dev/{project_id}/{docker_repo}/bqsc-inspection-dispatcher-service:latest"
inspector_service_image = f"{compute_region}-docker.pkg.dev/{project_id}/{docker_repo}/bqsc-inspector-service:latest"
tagger_service_image = f"{compute_region}-docker.pkg.dev/{project_id}/{docker_repo}/bqsc-tagger-service:latest"

inspection_cron_expression = "0 0 * * *"
tagging_cron_expression = "0 12 1 * *"

table_scan_limits_json_config = {
  "limitType": "NUMBER_OF_ROWS",
  "limits": {
    "10000":"10",
    "100000":"100",
    "1000000":"1000"
  }
}

promote_mixed_info_types = False

inspection_dispatcher_pubsub_topic = "inspection_dispatcher_pubsub_topic"
inspection_dispatcher_pubsub_sub = "inspection_dispatcher_pubsub_sub"
inspector_pubsub_topic = "inspector_topic"
inspector_pubsub_sub = "inspector_push_sub"
tagger_pubsub_topic = "tagger_pubsub_topic"
tagger_pubsub_sub = "tagger_pubsub_sub"
auto_dlp_results_table_name = "auto_dlp_results"
inspection_dispatcher_service_name = "s1b-inspection-dispatcher"
inspector_service_name = "s2-inspector"
sa_inspector = f"inspector"
sa_inspector_tasks = f"inspector-tasks"
inspection_scheduler_name = "inspection-scheduler"
standard_dlp_results_table_name = "standard_dlp_results"
sa_inspection_dispatcher  = f"inspection-dispatcher"
sa_inspection_dispatcher_tasks = f"inspection-dispatcher-tasks"
dlp_max_findings_per_item = 0
dlp_min_likelihood = "LIKELY"
dlp_sampling_method = 2
tagging_dispatcher_pubsub_sub = "tagging_dispatcher_pubsub_sub"
tagging_dispatcher_pubsub_topic = "tagging_dispatcher_pubsub_topic"
tagging_dispatcher_service_name = "s1a-tagging-dispatcher"
log_sink_name = "sc_bigquery_log_sink"
sa_tagger = f"tagger"
sa_tagger_tasks = f"tagger-tasks"
tagging_scheduler_name = "tagging-scheduler"
tagger_role = "tagger_role"
tagger_service_name = "s3-tagger"
sa_tagging_dispatcher = f"tagging-dispatcher"
sa_tagging_dispatcher_tasks = f"tag-dispatcher-tasks"


#description = "Max period for the cloud run service to complete a request. Otherwise, it terminates with HTTP 504 and NAK to PubSub (retry)"
#type = number
# Dispatcher might need relatively long time to process large BigQuery scan scopes  
dispatcher_service_timeout_seconds = 540
# 9m

#description = "This value is the maximum time after a subscriber receives a message before the subscriber should acknowledge the message. If it timeouts without ACK PubSub will retry the message."
#  type = number
#  // This should be higher than the service_timeout_seconds to avoid retrying messages that are still processing
#  // range is 10 to 600 
dispatcher_subscription_ack_deadline_seconds = 600
# 10m

# description = "How long to retain unacknowledged messages in the subscription's backlog"
#  type = string
# In case of unexpected problems we want to avoid a buildup that re-trigger functions (e.g. Tagger issuing unnecessary BQ queries)
# min value must be at least equal to the ack_deadline_seconds
# Dispatcher should have the shortest retention possible because we want to avoid retries (on the app level as well)
#default = "600s"
dispatcher_subscription_message_retention_duration = "600s"

#description = "Max period for the cloud run service to complete a request. Otherwise, it terminates with HTTP 504 and NAK to PubSub (retry)"
#  type = number
#  # Tagger is using BQ batch jobs that might need time to start running and thus a relatively longer timeout
#  default = 540
#  # 9m
tagger_service_timeout_seconds = 540


#description = "This value is the maximum time after a subscriber receives a message before the subscriber should acknowledge the message. If it timeouts without ACK PubSub will retry the message."
#  type = number
#  // This should be higher than the service_timeout_seconds to avoid retrying messages that are still processing
#  // range is 10 to 600
#  default = 600
# 10m
tagger_subscription_ack_deadline_seconds = 600

# description = "How long to retain unacknowledged messages in the subscription's backlog"
#  type = string
#  # In case of unexpected problems we want to avoid a buildup that re-trigger functions (e.g. Tagger issuing unnecessary BQ queries)
#  # It also sets how long should we keep trying to process one run
#  # min value must be at least equal to the ack_deadline_seconds
#  # Inspector should have a relatively long retention to handle runs with large number of tables.
#  default = "86400s"
  # 24h
tagger_subscription_message_retention_duration = "86400s"


# Inspector settings.
#variable "inspector_service_timeout_seconds" {
#  description = "Max period for the cloud run service to complete a request. Otherwise, it terminates with HTTP 504 and NAK to PubSub (retry)"
#  type = number
#  default = 300
  # 5m
#}
inspector_service_timeout_seconds = 300

# description = "This value is the maximum time after a subscriber receives a message before the subscriber should acknowledge the message. If it timeouts without ACK PubSub will retry the message."
#  type = number
#  // This should be higher than the service_timeout_seconds to avoid retrying messages that are still processing
#  default = 420
# 7m
inspector_subscription_ack_deadline_seconds = 420

# description = "How long to retain unacknowledged messages in the subscription's backlog"
#  type = string
  # In case of unexpected problems we want to avoid a buildup that re-trigger functions (e.g. Tagger issuing unnecessary BQ queries)
  # It also sets how long should we keep trying to process one run
  # min value must be at least equal to the ack_deadline_seconds
  # Inspector should have a relatively long retention to handle runs with large number of tables.
#  default = "86400s"
# 24h
inspector_subscription_message_retention_duration = "86400s"