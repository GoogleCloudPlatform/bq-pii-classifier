package com.google.cloud.pso.bq_pii_classifier.functions.entities;

import com.google.cloud.pso.bq_pii_classifier.entities.InfoTypeInfo;
import com.google.cloud.pso.bq_pii_classifier.entities.TableSpec;
import org.junit.Test;

import java.util.Map;

import static org.junit.Assert.assertEquals;

public class InfoTypeInfoTest {

    @Test
    public void fromFullResource() {

        String input = "{\"BLOOD_TYPE\":{\"classification\":\"Health_PII\",\"labels\":[{\"key\":\"dg_data_category_health\",\"value\":\"yes\"}]}," +
                " \"STREET_ADDRESS\":{\"classification\":\"Location_PII\",\"labels\":[{\"key\":\"dg_data_category_location\",\"value\":\"yes\"}]}}";
        Map<String, InfoTypeInfo> map = InfoTypeInfo.fromJsonMap(input);

        assertEquals(2, map.size());
        assertEquals("Health_PII", map.get("BLOOD_TYPE").getClassification());
        assertEquals("dg_data_category_health", map.get("BLOOD_TYPE").getLabels().get(0).getKey());
        assertEquals("yes", map.get("BLOOD_TYPE").getLabels().get(0).getValue());
    }
}
