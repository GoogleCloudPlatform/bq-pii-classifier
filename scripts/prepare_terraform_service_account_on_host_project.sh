#!/bin/bash

#
# Copyright 2022 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     https://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

gcloud iam service-accounts create "${TF_SA}" \
    --description="Used by Terraform to deploy GCP resources" \
    --display-name="Terraform Service Account"

roles=(
  "roles/iam.roleAdmin"
  "roles/resourcemanager.projectIamAdmin"
  "roles/serviceusage.serviceUsageAdmin"
  "roles/iam.serviceAccountAdmin"
  "roles/iam.serviceAccountUser"
  "roles/iam.serviceAccountTokenCreator"
  "roles/bigquery.dataEditor"
  "roles/bigquery.user"
  "roles/bigquery.connectionAdmin"
  "roles/run.admin"
  "roles/pubsub.admin"
  "roles/logging.configWriter"
  "roles/datastore.owner"
  "roles/cloudfunctions.developer"
  "roles/dlp.admin"
  "roles/datacatalog.admin"
  "roles/cloudscheduler.admin"
  "roles/storage.admin"
)

for role in "${roles[@]}"; do
  echo "Granting ${role} .."
  gcloud projects add-iam-policy-binding "${PROJECT_ID}" \
    --member="serviceAccount:${TF_SA}@${PROJECT_ID}.iam.gserviceaccount.com" \
    --role="$role"
done