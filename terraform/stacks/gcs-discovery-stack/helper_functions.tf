########################################################################################################################
#                                            Helper Functions
########################################################################################################################


# Helper functions for data analysis and cost estimation
module "bq-remote-func-get-buckets-metadata" {
  source                    = "../../modules/bq-remote-function"
  function_name             = var.bq_remote_func_get_buckets_metadata
  cloud_function_src_dir    = "../helpers/bq-remote-functions/get-buckets-metadata"
  cloud_function_temp_dir   = "/tmp/get-buckets-metadata.zip"
  service_account_name      = var.sa_bq_remote_func_get_buckets_metadata
  function_entry_point      = "process_request"
  env_variables = {}
  project                   = var.project
  publishing_project        = var.publishing_project
  compute_region            = var.compute_region
  data_region               = var.data_region
  bigquery_dataset_name     = var.bq_results_dataset
  deployment_procedure_path = "modules/bq-remote-function/procedures/deploy_get_buckets_metadata_remote_func.tpl"
  cloud_functions_sa_extra_roles = []
}