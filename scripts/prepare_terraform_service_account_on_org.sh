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

set -e

echo "Preparing org ${1} .."

# To create DLP discovery service configurations on org and folder level
# Required to deploy terraform/stacks/gcs-auto-dlp
gcloud organizations add-iam-policy-binding "${1}" \
    --member="serviceAccount:${TF_SA}@${PROJECT_ID}.iam.gserviceaccount.com" \
    --role="roles/dlp.jobsEditor" \
    --condition="None"

gcloud organizations add-iam-policy-binding "${1}" \
    --member="serviceAccount:${TF_SA}@${PROJECT_ID}.iam.gserviceaccount.com" \
    --role="roles/dlp.jobTriggersEditor" \
    --condition="None"

# To create custom roles and assign roles to users
# Required to deploy terraform/modules/data-folder-permissions-for-gcs-stack. Omit otherwise.
gcloud organizations add-iam-policy-binding "${1}" \
    --member="serviceAccount:${TF_SA}@${PROJECT_ID}.iam.gserviceaccount.com" \
    --role="roles/iam.securityAdmin" \
    --condition="None"

gcloud organizations add-iam-policy-binding "${1}" \
    --member="serviceAccount:${TF_SA}@${PROJECT_ID}.iam.gserviceaccount.com" \
    --role="roles/iam.organizationRoleAdmin" \
    --condition="None"