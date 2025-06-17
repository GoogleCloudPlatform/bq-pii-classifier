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

package com.google.cloud.oss.solutions.annotations.entities;

import com.google.gson.Gson;
import com.google.gson.reflect.TypeToken;
import java.lang.reflect.Type;
import java.util.List;
import java.util.Map;

/** Represents information about an infoType, including its classification and associated labels. */
public record InfoTypeInfo(String classification, List<ResourceLabel> labels) {

  /**
   * Parses a JSON string into a map of infoType names to {@code InfoTypeInfo} objects.
   *
   * @param jsonStr The JSON string to parse.
   * @return A map of infoType names to {@code InfoTypeInfo} objects.
   */
  public static Map<String, InfoTypeInfo> fromJsonMap(String jsonStr) {
    Gson gson = new Gson();
    Type mapType = new TypeToken<Map<String, InfoTypeInfo>>() {}.getType();
    return gson.fromJson(jsonStr, mapType);
  }
}
