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

# exit script when errors occur
set -e

# set the working dir as the scripts directory
cd "$(dirname "$0")"

gcloud auth configure-docker "${COMPUTE_REGION}-docker.pkg.dev"

cd ../services
mvn install

cd dispatcher-inspection-app
mvn compile jib:build -Dimage="${INSPECTION_DISPATCHER_IMAGE}"

cd ../inspector-app
mvn compile jib:build -Dimage="${INSPECTOR_IMAGE}"

cd ../listener-app
mvn compile jib:build -Dimage="${LISTENER_IMAGE}"

