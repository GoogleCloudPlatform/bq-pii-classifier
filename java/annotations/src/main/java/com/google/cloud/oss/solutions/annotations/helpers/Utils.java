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

import com.google.gson.Gson;
import com.google.gson.JsonArray;
import com.google.gson.JsonElement;
import com.google.gson.JsonObject;
import com.google.gson.reflect.TypeToken;
import java.lang.reflect.Type;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.HashMap;
import java.util.List;
import java.util.StringTokenizer;

/** Utility class with helper methods. */
public class Utils {

  public static List<String> tokenize(String input, String delimiter, boolean required) {
    List<String> output = new ArrayList<>();

    if (input.isBlank() && required) {
      throw new IllegalArgumentException(String.format("Input string '%s' is blank.", input));
    }

    if (input.isBlank() && !required) {
      return output;
    }

    StringTokenizer tokens = new StringTokenizer(input, delimiter);
    while (tokens.hasMoreTokens()) {
      output.add(tokens.nextToken().trim());
    }
    if (required && output.size() == 0) {
      throw new IllegalArgumentException(
          String.format("No tokens found in string: '%s' using delimiter '%s'", input, delimiter));
    }
    return output;
  }

  public static String getConfigFromEnv(String config, boolean required) {
    String value = System.getenv().getOrDefault(config, "");

    if (required && value.isBlank()) {
      throw new IllegalArgumentException(
          String.format("Missing environment variable '%s'", config));
    }

    return value;
  }

  /**
   * @param policyTagId e.g.
   *     projects/<project>/locations/<location>/taxonomies/<taxonomyID>/policyTags/<policyTagID
   * @return e.g. projects/<project>/locations/<location>/taxonomies/<taxonomyID>
   */
  public static String extractTaxonomyIdFromPolicyTagId(String policyTagId) {

    List<String> tokens = tokenize(policyTagId, "/", true);
    int taxonomiesIndex = tokens.indexOf("taxonomies");
    return String.join("/", tokens.subList(0, taxonomiesIndex + 2));
  }

  public static String getArgFromJsonParams(
      JsonObject requestJson, String argName, boolean required) {

    String arg = "";

    // check in Json
    if (requestJson != null && requestJson.has(argName)) {
      arg = requestJson.get(argName).getAsString();
    }

    // validate it exists
    if (required) {
      if (arg.isBlank()) {
        throw new IllegalArgumentException(String.format("%s is required", argName));
      }
    }

    return arg;
  }

  public static List<String> getArgFromJsonParamsAsList(
      JsonObject requestJson, String argName, boolean required) {

    JsonArray jsonArray = new JsonArray();

    // check in Json
    if (requestJson != null && requestJson.has(argName)) {
      jsonArray = requestJson.get(argName).getAsJsonArray();
    }

    // validate it exists
    if (required) {
      if (jsonArray.size() == 0) {
        throw new IllegalArgumentException(String.format("%s is required", argName));
      }
    }

    Type listType = new TypeToken<List<String>>() {}.getType();

    return new Gson().fromJson(jsonArray, listType);
  }

  public static HashMap<String, List<String>> parseJsonToMap(
      String jsonString, String keyAttribute, String valuesAttribute) {
    Gson gson = new Gson();
    JsonArray jsonArray = gson.fromJson(jsonString, JsonArray.class);
    HashMap<String, List<String>> map = new HashMap<>();

    for (JsonElement jsonElement : jsonArray) {
      JsonObject jsonObject = jsonElement.getAsJsonObject();
      String region = jsonObject.get(keyAttribute).getAsString();
      List<String> templateIds = gson.fromJson(jsonObject.get(valuesAttribute), List.class);
      map.put(region, templateIds);
    }

    return map;
  }

  public static String extractDLPRegionFromJobNameToBQRegion(String dlpJobName) {
    // e.g. dlp job name structure projects/<project>/locations/<location>/dlpJobs/<job-id>
    // dlp region "europe" maps to bq region "eu"
    String dlpRegion = dlpJobName.split("/")[3];
    return dlpRegion.equals("europe") ? "eu" : dlpRegion;
  }

  public static String stripLeadingAndTrailingSlashes(String resourceName) {
    if (resourceName == null) {
      throw new IllegalArgumentException("ResourceName is null");
    }

    if (resourceName.isEmpty() || resourceName.isBlank()) {
      throw new IllegalArgumentException("ResourceName is empty or blank");
    }

    String stripped = resourceName;

    // Remove leading slashes
    while (stripped.startsWith("/")) {
      stripped = stripped.substring(1);
    }

    // Remove trailing slashes
    while (stripped.endsWith("/")) {
      stripped = stripped.substring(0, stripped.length() - 1);
    }

    return stripped;
  }

  public static Boolean parseBooleanOrFail(String s) {
    if (s == null) {
      throw new IllegalArgumentException("Input string cannot be null.");
    }

    String lowerCaseS = s.toLowerCase();
    if (lowerCaseS.equals("true")) {
      return Boolean.TRUE;
    } else if (lowerCaseS.equals("false")) {
      return Boolean.FALSE;
    } else {
      throw new IllegalArgumentException("Invalid boolean string: '" + s + "'");
    }
  }

  public static String generateBucketEntityId(String project, String bucketName) {
    return String.format(
        "projects/%s/buckets/%s",
        project == null ? "NA" : project, bucketName == null ? "NA" : bucketName);
  }

  /**
   * From: organizations/123/locations/europe/tableDataProfiles/456 -> extracts
   * organizations/123/locations/europe
   *
   * @param profileName: dlp discovery service profile name
   * @return dlp profile parent
   */
  public static String extractDlpParentFromProfile(String profileName) {
    if (profileName == null || profileName.isEmpty()) {
      return null; // Or throw an exception, depending on your error handling policy
    }

    String[] parts = profileName.split("/");

    return String.join("/", Arrays.copyOfRange(parts, 0, 4));
  }
}
