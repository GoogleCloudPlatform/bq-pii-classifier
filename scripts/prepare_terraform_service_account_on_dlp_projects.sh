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

roles=(
  "roles/viewer"                   # to get project metadata (number)
  "roles/dlp.jobsEditor"           # to create project-level dlp configs
  "roles/dlp.jobTriggersEditor"    # to create project-level dlp configs
  "roles/resourcemanager.projectIamAdmin" # to grant permissions to annotations service accounts
)

for project in "$@"
do

  echo "Preparing DLP project ${project} .."

  for role in "${roles[@]}"; do
    echo "Granting ${role} on dlp project .."
    gcloud projects add-iam-policy-binding "${project}" \
      --member="serviceAccount:${TF_SA}@${PROJECT_ID}.iam.gserviceaccount.com" \
      --role="$role"
  done

done