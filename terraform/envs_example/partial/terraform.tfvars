#
#
#  Copyright 2025 Google LLC
#
#  Licensed under the Apache License, Version 2.0 (the "License");
#  you may not use this file except in compliance with the License.
#  You may obtain a copy of the License at
#
#       https://www.apache.org/licenses/LICENSE-2.0
#
#  Unless required by applicable law or agreed to in writing, software
#  distributed under the License is distributed on an "AS IS" BASIS,
#  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or
#  implied.
#  See the License for the specific language governing permissions and
#  limitations under the License.
#
#

terraform_service_account_email ="terraform@<PROJECT_ID>.iam.gserviceaccount.com"
application_project = "<PROJECT_ID>"
publishing_project = "PUBLISHING_PROJECT_ID"
compute_region = "us-central1"
data_region    = "us"
source_data_regions = ["europe-west3", "eu", "us"]
org_id         = 123 # The organization to deploy Cloud DLP discovery configurations to
terraform_data_deletion_protection = false # set to `true` for prod environments