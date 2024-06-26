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

package com.google.cloud.pso.bq_pii_classifier.functions.dispatcher;

import com.google.gson.Gson;
import org.junit.Test;

import java.util.ArrayList;
import java.util.Arrays;

import static org.junit.Assert.assertEquals;

public class BigQueryScopeTest {

        @Test
        public void fromJson() {

            String input = "{\n" +
                    "\"datasetExcludeList\":[],\n" +
                    "\"datasetIncludeList\":[],\n" +
                    "\"projectIncludeList\":[\"Project1\", \"Project2\"],\n" +
                    "\"tableExcludeList\":[]\n" +
                    "}";

            BigQueryScope expected = new BigQueryScope(
                    new ArrayList<>(Arrays.asList("Project1", "Project2")),
                    new ArrayList<>(),
                    new ArrayList<>(),
                    new ArrayList<>()
            );

            Gson gson = new Gson();
            BigQueryScope actual = gson.fromJson(input, BigQueryScope.class);

            assertEquals(expected, actual);
        }
}
