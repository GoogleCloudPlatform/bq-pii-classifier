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

package com.google.cloud.pso.bq_pii_classifier.functions.helpers;

import com.google.cloud.pso.bq_pii_classifier.helpers.Utils;
import org.junit.Test;

import static org.junit.Assert.assertEquals;

public class UtilsTest {

    @Test
    public void extractTaxonomyIdFromPolicyTagId() {

        String input = "projects/<project>/locations/<location>/taxonomies/<taxonomyID>/policyTags/<policyTagID";
        String expected = "projects/<project>/locations/<location>/taxonomies/<taxonomyID>";
        String actual = Utils.extractTaxonomyIdFromPolicyTagId(input);

        assertEquals(expected, actual);
    }

    @Test(expected = IllegalArgumentException.class)
    public void getConfigFromEnv_Required() {
        Utils.getConfigFromEnv("NA_VAR", true);
    }

    @Test
    public void getConfigFromEnv_NotRequired() {
        // should not fail because the VAR is not required
        Utils.getConfigFromEnv("NA_VAR", false);
    }
}