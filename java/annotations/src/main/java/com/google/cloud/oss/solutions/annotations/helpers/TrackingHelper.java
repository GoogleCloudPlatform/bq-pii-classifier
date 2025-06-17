/*
 *
 *  Copyright 2025 Google LLC
 *
 *  Licensed under the Apache License, Version 2.0 (the "License");
 *  you may not use this file except in compliance with the License.
 *  You may obtain a copy of the License at
 *
 *       https://www.apache.org/licenses/LICENSE-2.0
 *
 *  Unless required by applicable law or agreed to in writing, software
 *  distributed under the License is distributed on an "AS IS" BASIS,
 *  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or
 *  implied.
 *  See the License for the specific language governing permissions and
 *  limitations under the License.
 *
 */

package com.google.cloud.oss.solutions.annotations.helpers;

import java.util.UUID;

/** Helper class to generate tracking ids and run ids for the annotation process. */
public class TrackingHelper {

  public static final String DEFAULT_TRACKING_ID = "0000000000000-z";

  private static final String taggingRunSuffix = "-T";
  private static final String oneTimeTaggingSuffix = "-A";
  private static final String gcsSuffix = "-GS";
  private static final String bigQuerySuffix = "-BQ";
  private static final Integer suffixLength = 5;

  public static String generateTaggingRunIdForBigQuery() {
    return generateRunId(taggingRunSuffix, bigQuerySuffix);
  }

  public static String generateOneTimeTaggingSuffixForBigQuery() {
    return generateRunId(oneTimeTaggingSuffix, bigQuerySuffix);
  }

  public static String generateTaggingRunIdForGcs() {
    return generateRunId(taggingRunSuffix, gcsSuffix);
  }

  public static String generateOneTimeTaggingSuffixForGcs() {
    return generateRunId(oneTimeTaggingSuffix, gcsSuffix);
  }

  private static String generateRunId(String type, String system) {
    return String.format("%s%s%s", System.currentTimeMillis(), type, system);
  }

  public static String parseRunIdAsPrefix(String str) {
    // currentTimeMillis() will always be 13 chars between Sep 9 2001 at 01:46:40.000 UTC and Nov 20
    // 2286 at 17:46:39.999 UTC
    return str.substring(0, (13 + suffixLength));
  }

  public static String generateTrackingId(String runId) {

    // using UUIDs only resulted in unexpected collisions in some runs.
    // adding table name hash for extra "randomness"

    return String.format("%s-%s", runId, UUID.randomUUID());
  }
}
