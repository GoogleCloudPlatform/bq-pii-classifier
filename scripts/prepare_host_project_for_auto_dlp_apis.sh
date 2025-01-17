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

for project_number in "$@"
do

  echo "Preparing access to host project resources for DLP service account  in project number ${project_number} .."

  echo "Granting Editor role for serviceAccount:service-${project_number}@dlp-api.iam.gserviceaccount.com on Auto DLP dataset ${AUTO_DLP_DATASET}"

  bq query --location "${DATA_REGION}" --nouse_legacy_sql \
  "GRANT \`roles/bigquery.dataEditor\` ON SCHEMA \`${AUTO_DLP_DATASET}\` TO 'serviceAccount:service-${project_number}@dlp-api.iam.gserviceaccount.com'"

  echo "Granting Publisher role for serviceAccount:service-${project_number}@dlp-api.iam.gserviceaccount.com on the Tagger Pub/Sub topic"

  gcloud pubsub topics add-iam-policy-binding tagger_topic \
      --project="${PROJECT_ID}" \
      --member="serviceAccount:service-${project_number}@dlp-api.iam.gserviceaccount.com" \
      --role="roles/pubsub.publisher"


done