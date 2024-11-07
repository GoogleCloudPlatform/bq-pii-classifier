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

for project in "$@"
do

echo "Preparing data project ${project} .."

# This allow terraform to grant required iam roles to service accounts used by the solution (e.g. read bq data)
# Granting the IAM roles happen in Terraform or the scripts/prepare_data_projects_for_standard_mode.sh and scripts/prepare_data_projects_for_auto_dlp_mode.sh
gcloud projects add-iam-policy-binding "${project}" \
    --member="serviceAccount:${TF_SA}@${PROJECT_ID}.iam.gserviceaccount.com" \
    --role="roles/iam.securityAdmin"

done