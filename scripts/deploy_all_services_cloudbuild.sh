#!/bin/bash

#
# /*
#  * Copyright 2023 Google LLC
#  *
#  * Licensed under the Apache License, Version 2.0 (the "License");
#  * you may not use this file except in compliance with the License.
#  * You may obtain a copy of the License at
#  *
#  *     https://www.apache.org/licenses/LICENSE-2.0
#  *
#  * Unless required by applicable law or agreed to in writing, software
#  * distributed under the License is distributed on an "AS IS" BASIS,
#  * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#  * See the License for the specific language governing permissions and
#  * limitations under the License.
#  */
#

# exit script when errors occur
set -e

# set the working dir as the scripts directory
cd "$(dirname "$0")"

cd ../services

# make sure that the project is valid before submitting a build job
mvn install

gcloud builds submit \
--project $PROJECT_ID \
--region $COMPUTE_REGION \
--config cloudbuild_deploy_all_services.yaml \
--substitutions _TAGGING_DISPATCHER_IMAGE=${TAGGING_DISPATCHER_IMAGE},_TAGGER_IMAGE=${TAGGER_IMAGE},_INSPECTION_DISPATCHER_IMAGE=${INSPECTION_DISPATCHER_IMAGE},_INSPECTOR_IMAGE=${INSPECTOR_IMAGE}

