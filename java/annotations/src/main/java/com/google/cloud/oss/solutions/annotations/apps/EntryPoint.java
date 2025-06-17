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

package com.google.cloud.oss.solutions.annotations.apps;

import com.google.cloud.oss.solutions.annotations.apps.bigquery.BigQueryTaggerController;
import com.google.cloud.oss.solutions.annotations.apps.dispatcher.BigQueryDispatcher;
import com.google.cloud.oss.solutions.annotations.apps.dispatcher.GcsDispatcher;
import com.google.cloud.oss.solutions.annotations.apps.storage.GcsTaggerController;

/** Main class that acts as an entrypoint for all the supported apps. */
public class EntryPoint {
  public static void main(String[] args) throws Exception {

    switch (args[0].toLowerCase()) {
      case "bq-dispatcher" -> BigQueryDispatcher.main(args);
      case "bq-tagger" -> BigQueryTaggerController.main(new String[0]);
      case "gcs-dispatcher" -> GcsDispatcher.main(args);
      case "gcs-tagger" -> GcsTaggerController.main(new String[0]);
      default ->
          throw new Exception(
              String.format("Provided entry point is not supported: %s", args[0].toLowerCase()));
    }
  }
}
