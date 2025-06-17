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

package com.google.cloud.oss.solutions.annotations.apps.storage;

import com.google.cloud.oss.solutions.annotations.entities.InfoTypeInfo;
import com.google.cloud.oss.solutions.annotations.entities.NonRetryableApplicationException;
import com.google.cloud.oss.solutions.annotations.functions.tagger.gcs.GcsTaggerConfig;
import com.google.cloud.oss.solutions.annotations.helpers.Utils;
import com.google.cloud.oss.solutions.annotations.services.gcs.GcsService;
import com.google.cloud.oss.solutions.annotations.services.gcs.GcsServiceImpl;
import java.util.Map;

/** Environment class to get all the environment variables needed for the application. */
public class Environment {

  private final GcsService gcsService;

  public Environment() {
    gcsService = new GcsServiceImpl();
  }

  public GcsTaggerConfig toConfig() throws NonRetryableApplicationException {
    return new GcsTaggerConfig(
        getProjectId(), getIsDryRunLabels(), getInfoTypeMap(), getExistingLabelsRegex());
  }

  public String getProjectId() {
    return Utils.getConfigFromEnv("PROJECT_ID", true);
  }

  public Boolean getIsDryRunLabels() {
    return Utils.parseBooleanOrFail(Utils.getConfigFromEnv("IS_DRY_RUN_LABELS", true));
  }

  public Map<String, InfoTypeInfo> getInfoTypeMap() throws NonRetryableApplicationException {
    String filePath = Utils.getConfigFromEnv("INFO_TYPE_MAP", true);
    String json = gcsService.getFileContent(filePath);

    return InfoTypeInfo.fromJsonMap(json);
  }

  public String getExistingLabelsRegex() {
    return Utils.getConfigFromEnv("EXISTING_LABELS_REGEX", true);
  }
}
