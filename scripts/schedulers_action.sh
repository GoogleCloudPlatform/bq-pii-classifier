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

SCHEDULERS=$(gcloud scheduler jobs list --format="value(ID)" --project="${PROJECT_ID}")

set -f                      # avoid globbing (expansion of *).
ARRAY=(${SCHEDULERS// / })
for i in "${!ARRAY[@]}"
do
    echo "$1 ${ARRAY[i]}.."
    gcloud scheduler jobs "${1}" "${ARRAY[i]}"
done
