package com.google.cloud.pso.bq_pii_classifier.entities;

import static org.junit.Assert.assertEquals;

import java.util.Map;
import org.junit.Test;

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
