/*
 * Copyright 2022 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     https://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

package com.google.cloud.pso.bq_pii_classifier.helpers;

import com.google.cloud.pso.bq_pii_classifier.entities.TableSpec;
import org.apache.commons.codec.digest.DigestUtils;

import java.util.UUID;

public class TrackingHelper {

    private static final String taggingRunSuffix = "-T";
    private static final String inspectionRunSuffix = "-I";
    private static final Integer suffixLength = 2;

    public static String generateTaggingRunId(){
        return generateRunId(taggingRunSuffix);
    }

    public static String generateInspectionRunId(){
        return generateRunId(inspectionRunSuffix);
    }

    private static String generateRunId(String suffix){
        return String.format("%s%s", System.currentTimeMillis(), suffix);
    }

    public static String parseRunIdAsPrefix(String str){
        // currentTimeMillis() will always be 13 chars between Sep 9 2001 at 01:46:40.000 UTC and Nov 20 2286 at 17:46:39.999 UTC
        return str.substring(0, (13 + suffixLength));
    }

    public static String generateTrackingId (String runId, String table){

        // using UUIDs only resulted in unexpected collisions in some runs.
        // adding table name hash for extra "randomness"

        return String.format("%s-%s-%s", runId, UUID.randomUUID().toString(), table.hashCode());
    }

    /**
     *
     * @param jobName Dlp Job name in format projects/locations/dlpJobs/i-<tracking-number>
     * @return tracking-number part
     */
    public static String extractTrackingIdFromJobName(String jobName){
        String [] splits = jobName.split("/");
        return  splits[splits.length-1].substring(2);
    }

}
