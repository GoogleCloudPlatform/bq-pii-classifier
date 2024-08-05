# /*
# * Copyright 2023 Google LLC
# *
# * Licensed under the Apache License, Version 2.0 (the "License");
# * you may not use this file except in compliance with the License.
# * You may obtain a copy of the License at
# *
# *     https://www.apache.org/licenses/LICENSE-2.0
# *
# * Unless required by applicable law or agreed to in writing, software
# * distributed under the License is distributed on an "AS IS" BASIS,
# * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# * See the License for the specific language governing permissions and
# * limitations under the License.
# */

output "bq_connection_sa_email" {
  value = google_bigquery_connection.connection.cloud_resource[0].service_account_id
}

output "deployment_procedure" {
  value = google_bigquery_routine.routine_deploy_functions.routine_id
}

output "cloud_function_sa_email" {
  value = google_service_account.sa_function.email
}

output "deploy_job_status" {
  value = google_bigquery_job.deploy_remote_functions_job.status
}
