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

package com.google.cloud.pso.bq_pii_classifier.helpers;

import com.google.gson.Gson;
import com.google.gson.JsonArray;
import com.google.gson.JsonObject;
import com.google.gson.reflect.TypeToken;

import java.lang.reflect.Type;
import java.util.ArrayList;
import java.util.List;
import java.util.StringTokenizer;

public class Utils {

    public static List<String> tokenize(String input, String delimiter, boolean required) {
        List<String> output = new ArrayList<>();

        if(input.isBlank() && required){
            throw new IllegalArgumentException(String.format(
                    "Input string '%s' is blank.",
                    input
            ));
        }

        if(input.isBlank() && !required){
            return output;
        }

        StringTokenizer tokens = new StringTokenizer(input, delimiter);
        while (tokens.hasMoreTokens()) {
            output.add(tokens.nextToken().trim());
        }
        if (required && output.size() == 0) {
            throw new IllegalArgumentException(String.format(
                    "No tokens found in string: '%s' using delimiter '%s'",
                    input,
                    delimiter
            ));
        }
        return output;
    }

    public static String getConfigFromEnv(String config, boolean required){
        String value = System.getenv().getOrDefault(config, "");

        if(required && value.isBlank()){
            throw new IllegalArgumentException(String.format("Missing environment variable '%s'",config));
        }

        return value;
    }

    /**
     *
     * @param policyTagId e.g. projects/<project>/locations/<location>/taxonomies/<taxonomyID>/policyTags/<policyTagID
     * @return e.g. projects/<project>/locations/<location>/taxonomies/<taxonomyID>
     */
    public static String extractTaxonomyIdFromPolicyTagId(String policyTagId){

        List<String> tokens = tokenize(policyTagId, "/", true);
        int taxonomiesIndex = tokens.indexOf("taxonomies");
        return String.join("/", tokens.subList(0,taxonomiesIndex+2));
    }

    public static String getArgFromJsonParams(JsonObject requestJson, String argName, boolean required) {

        String arg = "";

        // check in Json
        if (requestJson != null && requestJson.has(argName)) {
            arg = requestJson.get(argName).getAsString();
        }

        // validate it exists
        if(required) {
            if (arg.isBlank())
                throw new IllegalArgumentException(String.format("%s is required", argName));
        }

        return arg;
    }

    public static List<String> getArgFromJsonParamsAsList(JsonObject requestJson, String argName, boolean required) {

        JsonArray  jsonArray = new JsonArray();

        // check in Json
        if (requestJson != null && requestJson.has(argName)) {
            jsonArray = requestJson.get(argName).getAsJsonArray();
        }

        // validate it exists
        if(required) {
            if (jsonArray.size() == 0)
                throw new IllegalArgumentException(String.format("%s is required", argName));
        }

        Type listType = new TypeToken<List<String>>() {}.getType();

        return new Gson().fromJson(jsonArray, listType);
    }

}
