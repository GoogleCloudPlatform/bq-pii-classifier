package com.google.cloud.pso.bq_pii_classifier.services.gcs;

import com.google.cloud.pso.bq_pii_classifier.entities.ResourceLabelingAction;
import org.junit.Test;

import java.util.AbstractMap;
import java.util.HashMap;
import java.util.Map;
import java.util.regex.Pattern;

import static org.junit.Assert.assertEquals;

public class GcsServiceImplTest {

    @Test
    public void test (){

        Map<String, String> bucketLabels = new HashMap<>();
        bucketLabels.put("dg_1", "v1");
        bucketLabels.put("dg_2", "v2");
        bucketLabels.put("dg_to_remove", "vr");
        bucketLabels.put("not_dg_label", "vn");

        Map<String, String> newLabels = new HashMap<>();
        newLabels.put("dg_1", "v1");
        newLabels.put("dg_2", "v2_new");
        newLabels.put("dg_3", "v3");

        Map<Map.Entry<String, String>, ResourceLabelingAction> expectedLabelsWithActions = new HashMap<>();
        expectedLabelsWithActions.put(new AbstractMap.SimpleEntry<>("dg_1", "v1"),
                ResourceLabelingAction.NO_CHANGE);
        expectedLabelsWithActions.put(new AbstractMap.SimpleEntry<>("dg_2", "v2_new"),
                ResourceLabelingAction.NEW_VALUE);
        expectedLabelsWithActions.put(new AbstractMap.SimpleEntry<>("dg_3", "v3"),
                ResourceLabelingAction.NEW_KEY);
        expectedLabelsWithActions.put(new AbstractMap.SimpleEntry<>("dg_to_remove", "vr"),
                ResourceLabelingAction.DELETE);
        expectedLabelsWithActions.put(new AbstractMap.SimpleEntry<>("not_dg_label", "vn"),
                ResourceLabelingAction.NO_CHANGE);

        Map<String, String> expectedLabels = new HashMap<>();
        expectedLabels.put("dg_1", "v1");
        expectedLabels.put("dg_2", "v2_new");
        expectedLabels.put("dg_3", "v3");
        expectedLabels.put("not_dg_label", "vn");


        Map<Map.Entry<String, String>, ResourceLabelingAction> labelsWithAction = GcsServiceImpl.computeLabelsActions(bucketLabels,
                newLabels,
                "^dg_");

        Map<String, String> finalLabels = GcsServiceImpl.filterLabelsToAdd(labelsWithAction);

        assertEquals(expectedLabelsWithActions, labelsWithAction);
        assertEquals(expectedLabels, finalLabels);
    }
}
