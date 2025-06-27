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

set -e

echo "Creating docker repo .."

# create a docker repo to store the services container image
gcloud artifacts repositories create "${DOCKER_REPO_NAME}" \
  --repository-format=docker \
  --project="${PROJECT_ID}" \
  --location="${COMPUTE_REGION}" \
  --description="Data annotations docker repository"

# Cloud Build prep

echo "Creating compute default service identity  .."
# create the default compute engine service account
gcloud beta services identity create --service=compute.googleapis.com --project="${PROJECT_ID}"

# wait a bit until the SA is propagated
sleep 5

PROJECT_NUMBER=$(gcloud projects describe "${PROJECT_ID}" --format="value(projectNumber)")

echo "Granting permissions for compute default service identity  .."

# grant the compute engine service account storage permissions to be able to use the Cloud Build bucket
gcloud projects add-iam-policy-binding "${PROJECT_ID}" \
  --member="serviceAccount:${PROJECT_NUMBER}-compute@developer.gserviceaccount.com" \
  --role="roles/storage.admin"

# grant the compute engine service account (used by cloud build jobs) permissions to push docker images to GAR
gcloud projects add-iam-policy-binding "${PROJECT_ID}" \
  --member="serviceAccount:${PROJECT_NUMBER}-compute@developer.gserviceaccount.com" \
  --role="roles/artifactregistry.writer"

