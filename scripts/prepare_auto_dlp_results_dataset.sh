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

echo "Setting access for TAGGING_DISPATCHER service account.. "

bq query --location "${DATA_REGION}" --nouse_legacy_sql \
"GRANT \`roles/bigquery.dataViewer\` ON SCHEMA ${AUTO_DLP_DATASET} TO 'serviceAccount:${SA_TAGGING_DISPATCHER_EMAIL}'"

echo "Setting access for TAGGER service account.. "

bq query --location "${DATA_REGION}" --nouse_legacy_sql \
"GRANT \`roles/bigquery.dataViewer\` ON SCHEMA ${AUTO_DLP_DATASET} TO 'serviceAccount:${SA_TAGGER_EMAIL}'"

