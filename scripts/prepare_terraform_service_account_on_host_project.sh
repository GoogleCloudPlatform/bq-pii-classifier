#!/bin/bash

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

gcloud iam service-accounts create "${TF_SA}" \
    --project="${PROJECT_ID}" \
    --description="Used by Terraform to deploy GCP resources" \
    --display-name="Terraform Service Account"

roles_on_host_project=(
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
  "roles/storage.admin"
  "roles/workflows.editor"
  "roles/artifactregistry.reader"
)

for role in "${roles_on_host_project[@]}"; do
  echo "Granting ${role} on host project .."
  gcloud projects add-iam-policy-binding "${PROJECT_ID}" \
    --member="serviceAccount:${TF_SA}@${PROJECT_ID}.iam.gserviceaccount.com" \
    --role="$role"
done

# grant impersonation rights to the current user on the TF service account to be able to run Terraform locally

CURRENT_USER=$(gcloud config list account --format "value(core.account)")

gcloud iam service-accounts add-iam-policy-binding "${TF_SA}@${PROJECT_ID}.iam.gserviceaccount.com" \
    --project="${PROJECT_ID}" \
    --member="user:${CURRENT_USER}" \
    --role="roles/iam.serviceAccountTokenCreator"

gcloud iam service-accounts add-iam-policy-binding "${TF_SA}@${PROJECT_ID}.iam.gserviceaccount.com" \
    --project="${PROJECT_ID}" \
    --member="user:${CURRENT_USER}" \
    --role="roles/iam.serviceAccountUser"