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

import static org.junit.Assert.assertEquals;
import static org.junit.Assert.assertThrows;

import java.util.HashMap;
import java.util.List;
import org.junit.Test;

/** Unit tests for the Utils class. */
public class UtilsTest {

  @Test
  public void extractTaxonomyIdFromPolicyTagId() {

    String input =
        "projects/<project>/locations/<location>/taxonomies/<taxonomyID>/policyTags/<policyTagID";
    String expected = "projects/<project>/locations/<location>/taxonomies/<taxonomyID>";
    String actual = Utils.extractTaxonomyIdFromPolicyTagId(input);

    assertEquals(expected, actual);
  }

  @Test
  public void getConfigFromEnv_Required() {
    assertThrows(IllegalArgumentException.class, () -> Utils.getConfigFromEnv("NA_VAR", true));
  }

  @Test
  public void getConfigFromEnv_NotRequired() {
    // should not fail because the VAR is not required
    Utils.getConfigFromEnv("NA_VAR", false);
  }

  @Test
  public void testParseJsonToMap() {
    String jsonString =
        "[{\"ids\":[\"projects/p/locations/europe/inspectTemplates/1\","
            + " \"projects/p/locations/europe/inspectTemplates/2\"],\"region\":\"eu\"},{\"ids\":[\"projects/p/locations/europe-west3/inspectTemplates/1\"],\"region\":\"europe-west3\"}]";

    HashMap<String, List<String>> actual = Utils.parseJsonToMap(jsonString, "region", "ids");

    HashMap<String, List<String>> expected = new HashMap<>();
    expected.put(
        "eu",
        List.of(
            "projects/p/locations/europe/inspectTemplates/1",
            "projects/p/locations/europe/inspectTemplates/2"));
    expected.put("europe-west3", List.of("projects/p/locations/europe-west3/inspectTemplates/1"));

    assertEquals(expected, actual);
  }

  @Test
  public void testExtractDLPRegionFromJobNameToBQRegion() {

    assertEquals(
        "eu",
        Utils.extractDLPRegionFromJobNameToBQRegion("projects/p/locations/europe/dlpJobs/job"));
    assertEquals(
        "europe-west3",
        Utils.extractDLPRegionFromJobNameToBQRegion(
            "projects/p/locations/europe-west3/dlpJobs/job"));
  }

  @Test
  public void testStripLeadingAndTrailingSlashes() {

    assertEquals("path/to/resource", Utils.stripLeadingAndTrailingSlashes("path/to/resource"));
    assertEquals("path/to/resource", Utils.stripLeadingAndTrailingSlashes("/path/to/resource/"));
    assertEquals("path/to/resource", Utils.stripLeadingAndTrailingSlashes("/path/to/resource"));
    assertEquals("path/to/resource", Utils.stripLeadingAndTrailingSlashes("path/to/resource/"));
    assertEquals("path/to/resource", Utils.stripLeadingAndTrailingSlashes("//path/to/resource//"));

    assertEquals("resource", Utils.stripLeadingAndTrailingSlashes("resource"));

    assertThrows(
        IllegalArgumentException.class,
        () -> {
          Utils.stripLeadingAndTrailingSlashes(null);
        });

    assertThrows(
        IllegalArgumentException.class,
        () -> {
          Utils.stripLeadingAndTrailingSlashes("");
        });

    assertThrows(
        IllegalArgumentException.class,
        () -> {
          Utils.stripLeadingAndTrailingSlashes(" ");
        });

    assertEquals("", Utils.stripLeadingAndTrailingSlashes("/"));
    assertEquals("", Utils.stripLeadingAndTrailingSlashes("//"));
  }

  @Test
  public void testParseBoolean() {
    assertEquals(false, Utils.parseBooleanOrFail("FALSE"));
    assertEquals(false, Utils.parseBooleanOrFail("False"));
    assertEquals(false, Utils.parseBooleanOrFail("false"));

    assertEquals(true, Utils.parseBooleanOrFail("TRUE"));
    assertEquals(true, Utils.parseBooleanOrFail("True"));
    assertEquals(true, Utils.parseBooleanOrFail("true"));

    try {
      Utils.parseBooleanOrFail(null);
      // shouldn't reach this
      assertEquals(1, 0);
    } catch (Exception ex) {
      assertEquals(1, 1);
    }

    try {
      Utils.parseBooleanOrFail("not boolean");
      // shouldn't reach this
      assertEquals(1, 0);
    } catch (Exception ex) {
      assertEquals(1, 1);
    }
  }

  @Test
  public void testExtractParentFromDlpProfile() {
    assertEquals(
        "organizations/123/locations/europe",
        Utils.extractDlpParentFromProfile(
            "organizations/123/locations/europe/tableDataProfiles/456"));
  }
}
