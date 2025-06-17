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
import static org.junit.Assert.assertNull;

import com.google.cloud.oss.solutions.annotations.entities.ResourceLabelingAction;
import java.util.AbstractMap;
import java.util.HashMap;
import java.util.Map;
import org.junit.Test;

/** Unit tests for {@link LabelsHelper} */
public class LabelsHelperTest {

  @Test
  public void test_dg_regex() {

    Map<String, String> bucketLabels = new HashMap<>();
    bucketLabels.put("dg_1", "v1");
    bucketLabels.put("dg_2", "v2");
    bucketLabels.put("dg_to_remove", "vr");
    bucketLabels.put("not_dg_label", "vn");

    Map<String, String> newLabels = new HashMap<>();
    newLabels.put("dg_1", "v1");
    newLabels.put("dg_2", "v2_new");
    newLabels.put("dg_3", "v3");

    Map<Map.Entry<String, String>, ResourceLabelingAction> expectedLabelsWithActions =
        new HashMap<>();
    expectedLabelsWithActions.put(
        new AbstractMap.SimpleEntry<>("dg_1", "v1"), ResourceLabelingAction.NO_CHANGE);
    expectedLabelsWithActions.put(
        new AbstractMap.SimpleEntry<>("dg_2", "v2_new"), ResourceLabelingAction.NEW_VALUE);
    expectedLabelsWithActions.put(
        new AbstractMap.SimpleEntry<>("dg_3", "v3"), ResourceLabelingAction.NEW_KEY);
    expectedLabelsWithActions.put(
        new AbstractMap.SimpleEntry<>("dg_to_remove", "vr"), ResourceLabelingAction.DELETE);
    expectedLabelsWithActions.put(
        new AbstractMap.SimpleEntry<>("not_dg_label", "vn"), ResourceLabelingAction.NO_CHANGE);

    Map<String, String> expectedLabels = new HashMap<>();
    expectedLabels.put("dg_1", "v1");
    expectedLabels.put("dg_2", "v2_new");
    expectedLabels.put("dg_3", "v3");
    expectedLabels.put("dg_to_remove", null);
    expectedLabels.put("not_dg_label", "vn");

    Map<Map.Entry<String, String>, ResourceLabelingAction> labelsWithAction =
        LabelsHelper.computeLabelsActions(bucketLabels, newLabels, "^dg_");

    Map<String, String> finalLabels = LabelsHelper.removeToBeDeletedLabels(labelsWithAction);

    assertEquals(expectedLabelsWithActions, labelsWithAction);
    assertEquals(expectedLabels, finalLabels);
  }

  @Test
  public void test_never_match_regex() {

    Map<String, String> bucketLabels = new HashMap<>();
    bucketLabels.put("dg_1", "v1");
    bucketLabels.put("dg_2", "v2");
    bucketLabels.put("dg_to_remove", "vr");
    bucketLabels.put("not_dg_label", "vn");

    Map<String, String> newLabels = new HashMap<>();
    newLabels.put("dg_1", "v1");
    newLabels.put("dg_2", "v2_new");
    newLabels.put("dg_3", "v3");

    Map<Map.Entry<String, String>, ResourceLabelingAction> expectedLabelsWithActions =
        new HashMap<>();
    expectedLabelsWithActions.put(
        new AbstractMap.SimpleEntry<>("dg_1", "v1"), ResourceLabelingAction.NO_CHANGE);
    expectedLabelsWithActions.put(
        new AbstractMap.SimpleEntry<>("dg_2", "v2_new"), ResourceLabelingAction.NEW_VALUE);
    expectedLabelsWithActions.put(
        new AbstractMap.SimpleEntry<>("dg_3", "v3"), ResourceLabelingAction.NEW_KEY);
    expectedLabelsWithActions.put(
        new AbstractMap.SimpleEntry<>("dg_to_remove", "vr"), ResourceLabelingAction.NO_CHANGE);
    expectedLabelsWithActions.put(
        new AbstractMap.SimpleEntry<>("not_dg_label", "vn"), ResourceLabelingAction.NO_CHANGE);

    Map<String, String> expectedLabels = new HashMap<>();
    expectedLabels.put("dg_1", "v1");
    expectedLabels.put("dg_2", "v2_new");
    expectedLabels.put("dg_3", "v3");
    expectedLabels.put("dg_to_remove", "vr");
    expectedLabels.put("not_dg_label", "vn");

    // test with a regex that doesn't match anything (meaning, don't delete)
    Map<Map.Entry<String, String>, ResourceLabelingAction> labelsWithAction =
        LabelsHelper.computeLabelsActions(bucketLabels, newLabels, "(?!)");

    Map<String, String> finalLabels = LabelsHelper.removeToBeDeletedLabels(labelsWithAction);

    assertEquals(expectedLabelsWithActions, labelsWithAction);
    assertEquals(expectedLabels, finalLabels);
  }

  @Test
  public void test_remove() {

    Map<Map.Entry<String, String>, ResourceLabelingAction> inputLabelsWithActions = new HashMap<>();
    inputLabelsWithActions.put(
        new AbstractMap.SimpleEntry<>("no_change", "v1"), ResourceLabelingAction.NO_CHANGE);
    inputLabelsWithActions.put(
        new AbstractMap.SimpleEntry<>("new_value", "v2_new"), ResourceLabelingAction.NEW_VALUE);
    inputLabelsWithActions.put(
        new AbstractMap.SimpleEntry<>("new_key", "v3"), ResourceLabelingAction.NEW_KEY);
    inputLabelsWithActions.put(
        new AbstractMap.SimpleEntry<>("to_remove", "vr"), ResourceLabelingAction.DELETE);

    Map<String, String> actual = LabelsHelper.removeToBeDeletedLabels(inputLabelsWithActions);

    assertNull(actual.get("to_remove"));
    assertEquals("v1", actual.get("no_change"));
    assertEquals("v2_new", actual.get("new_value"));
    assertEquals("v3", actual.get("new_key"));
    assertEquals(4, actual.size());
  }
}
