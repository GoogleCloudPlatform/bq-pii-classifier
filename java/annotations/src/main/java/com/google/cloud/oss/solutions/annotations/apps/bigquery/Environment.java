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

package com.google.cloud.oss.solutions.annotations.apps.bigquery;

import com.google.common.reflect.TypeToken;
import com.google.gson.Gson;
import com.google.cloud.oss.solutions.annotations.entities.InfoTypeInfo;
import com.google.cloud.oss.solutions.annotations.entities.NonRetryableApplicationException;
import com.google.cloud.oss.solutions.annotations.functions.tagger.DatasetDomainMapKey;
import com.google.cloud.oss.solutions.annotations.functions.tagger.InfoTypePolicyTagMapKey;
import com.google.cloud.oss.solutions.annotations.functions.tagger.InfoTypePolicyTagMapValue;
import com.google.cloud.oss.solutions.annotations.functions.tagger.TaggerConfig;
import com.google.cloud.oss.solutions.annotations.helpers.Utils;
import com.google.cloud.oss.solutions.annotations.services.gcs.GcsService;
import com.google.cloud.oss.solutions.annotations.services.gcs.GcsServiceImpl;
import java.lang.reflect.Type;
import java.util.HashMap;
import java.util.HashSet;
import java.util.List;
import java.util.Map;

/** Environment class to get all the configuration from the environment variables */
public class Environment {

  private final GcsService gcsService;

  public Environment() {
    gcsService = new GcsServiceImpl();
  }

  /**
   * Convert the environment variables to a TaggerConfig object
   *
   * @return TaggerConfig object
   * @throws NonRetryableApplicationException
   */
  public TaggerConfig toConfig() throws NonRetryableApplicationException {
    return new TaggerConfig(
        getProjectId(),
        new HashSet<>(Utils.tokenize(getTaxonomies(), ",", true)),
        getIsDryRunTags(),
        getIsDryRunLabels(),
        getInfoTypeMap(),
        getExistingLabelsRegex(),
        getPromoteDlpOtherMatches(),
        getInfoTypePolicyTagMap(),
        getProjectDomainMap(),
        getDatasetDomainMap(),
        getDefaultDomainName());
  }

  /**
   * Get the project id from the environment variable
   *
   * @return project id
   */
  public String getProjectId() {
    return Utils.getConfigFromEnv("PROJECT_ID", true);
  }

  /**
   * Get the taxonomies from the environment variable
   *
   * @return taxonomies
   */
  public String getTaxonomies() {
    return Utils.getConfigFromEnv("TAXONOMIES", true);
  }

  /**
   * Get the dry run tags from the environment variable
   *
   * @return dry run tags
   */
  public Boolean getIsDryRunTags() {
    return Utils.parseBooleanOrFail(Utils.getConfigFromEnv("IS_DRY_RUN_TAGS", true));
  }

  /**
   * Get the dry run labels from the environment variable
   *
   * @return dry run labels
   */
  public Boolean getIsDryRunLabels() {
    return Utils.parseBooleanOrFail(Utils.getConfigFromEnv("IS_DRY_RUN_LABELS", true));
  }

  /**
   * Get the info type map from the environment variable
   *
   * @return info type map
   * @throws NonRetryableApplicationException
   */
  public Map<String, InfoTypeInfo> getInfoTypeMap() throws NonRetryableApplicationException {

    String filePath = Utils.getConfigFromEnv("INFO_TYPE_MAP", true);
    String json = gcsService.getFileContent(filePath);

    return InfoTypeInfo.fromJsonMap(json);
  }

  /**
   * Get the default domain name from the environment variable
   *
   * @return default domain name
   */
  public String getDefaultDomainName() {
    return Utils.getConfigFromEnv("DEFAULT_DOMAIN_NAME", true);
  }

  /**
   * Get the existing labels regex from the environment variable
   *
   * @return existing labels regex
   */
  public String getExistingLabelsRegex() {
    return Utils.getConfigFromEnv("EXISTING_LABELS_REGEX", true);
  }

  /**
   * Get the promote dlp other matches from the environment variable
   *
   * @return promote dlp other matches
   */
  public Boolean getPromoteDlpOtherMatches() {
    return Utils.parseBooleanOrFail(Utils.getConfigFromEnv("PROMOTE_DLP_OTHER_MATCHES", true));
  }

  /**
   * Get the info type policy tag map from the environment variable
   *
   * @return info type policy tag map
   * @throws NonRetryableApplicationException
   */
  public Map<InfoTypePolicyTagMapKey, InfoTypePolicyTagMapValue> getInfoTypePolicyTagMap()
      throws NonRetryableApplicationException {

    String filePath = Utils.getConfigFromEnv("INFO_TYPE_POLICY_TAG_MAP", true);
    String json = gcsService.getFileContent(filePath);

    Gson gson = new Gson();
    Type listType = new TypeToken<List<Map<String, String>>>() {}.getType();
    List<Map<String, String>> dataList = gson.fromJson(json, listType);

    Map<InfoTypePolicyTagMapKey, InfoTypePolicyTagMapValue> resultMap = new HashMap<>();

    for (Map<String, String> item : dataList) {
      resultMap.put(
          new InfoTypePolicyTagMapKey(
              item.get("info_type"), item.get("region"), item.get("domain")),
          new InfoTypePolicyTagMapValue(item.get("policy_tag_id"), item.get("classification")));
    }
    return resultMap;
  }

  /**
   * Get the project domain map from the environment variable
   *
   * @return project domain map
   */
  public Map<String, String> getProjectDomainMap() {
    String json = Utils.getConfigFromEnv("PROJECT_DOMAIN_MAP", true);

    Gson gson = new Gson();
    Type listType = new TypeToken<List<Map<String, String>>>() {}.getType();
    List<Map<String, String>> dataList = gson.fromJson(json, listType);

    Map<String, String> resultMap = new HashMap<>();

    for (Map<String, String> item : dataList) {
      resultMap.put(item.get("project"), item.get("domain"));
    }
    return resultMap;
  }

  /**
   * Get the dataset domain map from the environment variable
   *
   * @return dataset domain map
   */
  public Map<DatasetDomainMapKey, String> getDatasetDomainMap() {
    String json = Utils.getConfigFromEnv("DATASET_DOMAIN_MAP", true);

    Gson gson = new Gson();
    Type listType = new TypeToken<List<Map<String, String>>>() {}.getType();
    List<Map<String, String>> dataList = gson.fromJson(json, listType);

    Map<DatasetDomainMapKey, String> resultMap = new HashMap<>();

    for (Map<String, String> item : dataList) {
      resultMap.put(
          new DatasetDomainMapKey(item.get("project"), item.get("dataset")), item.get("domain"));
    }
    return resultMap;
  }
}
