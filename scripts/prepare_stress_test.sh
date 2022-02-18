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

# use FIFOs as semaphores and use them to ensure that new processes are spawned as soon as possible and that no more than N processes runs at the same time. But it requires more code.

task(){

   [[ ${#1} -lt 10 ]] && SUFFIX="0${1}" || SUFFIX="$1"
   echo  "${DESTINATION_TABLE_SPEC_PREFIX}_${SUFFIX}"
   bq cp --force "${ORIGIN_TABLE_SPEC}" "${DESTINATION_TABLE_SPEC_PREFIX}_${SUFFIX}";
}

N=50
(
for table in {1..1000}; do
   ((i=i%N)); ((i++==0)) && wait
   task "${table}" &
done
)

