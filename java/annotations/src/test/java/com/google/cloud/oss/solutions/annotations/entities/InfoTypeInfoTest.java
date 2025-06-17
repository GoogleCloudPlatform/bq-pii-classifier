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

import static org.junit.Assert.assertEquals;

import java.util.Map;
import org.junit.Test;

/** Unit tests for {@link InfoTypeInfo}. */
public class InfoTypeInfoTest {

  @Test
  public void fromFullResource() {
    String input =
        "{\"BLOOD_TYPE\":{\"classification\":\"Health_PII\",\"labels\":[{\"key\":\"dg_data_category_health\",\"value\":\"yes\"}]},"
            + " \"STREET_ADDRESS\":{\"classification\":\"Location_PII\",\"labels\":[{\"key\":\"dg_data_category_location\",\"value\":\"yes\"}]}}";
    Map<String, InfoTypeInfo> map = InfoTypeInfo.fromJsonMap(input);

    assertEquals(2, map.size());
    assertEquals("Health_PII", map.get("BLOOD_TYPE").classification());
    assertEquals("dg_data_category_health", map.get("BLOOD_TYPE").labels().get(0).key());
    assertEquals("yes", map.get("BLOOD_TYPE").labels().get(0).value());
  }
}
