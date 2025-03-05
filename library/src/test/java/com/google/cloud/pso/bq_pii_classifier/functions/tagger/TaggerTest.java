package com.google.cloud.pso.bq_pii_classifier.functions.tagger;

import com.google.cloud.Tuple;
import com.google.cloud.pso.bq_pii_classifier.entities.*;
import com.google.cloud.pso.bq_pii_classifier.services.findings.DlpFindingsReaderImpl;
import org.junit.Assert;
import org.junit.jupiter.api.Test;

import java.util.HashMap;
import java.util.List;
import java.util.Map;

import static org.junit.jupiter.api.Assertions.assertEquals;

public class TaggerTest {
  @Test
  public void testLookup() {

    TableColumnsInfoTypes tableColumnsInfoTypes =
        new TableColumnsInfoTypes(
            TableSpec.fromSqlString("p.d.t"),
            Map.of(
                "email_field", "EMAIL",
                "phone_field", "PHONE",
                "address_field", "STREET_ADDRESS"));

    Map<DatasetDomainMapKey, String> datasetDomainMapKeyStringMap =
        Map.of(new DatasetDomainMapKey("p", "d"), "domain_test");

    Map<InfoTypePolicyTagMapKey, InfoTypePolicyTagMapValue>
        infoTypePolicyTagMap =
            Map.of(
                new InfoTypePolicyTagMapKey("EMAIL", "eu", "domain_test"),
                new InfoTypePolicyTagMapValue("policy_tag_email", "pii"),
                new InfoTypePolicyTagMapKey("PHONE", "eu", "domain_test"),
                new InfoTypePolicyTagMapValue("policy_tag_phone", "pii"));

    Tuple<Map<String, PolicyTagInfo>, TableColumnsInfoTypes> actual = Tagger.lookupPolicyTags(
            tableColumnsInfoTypes,
            "EU",
            datasetDomainMapKeyStringMap,
            new HashMap<>(),
            "default_domain",
            infoTypePolicyTagMap);

    Map<String, PolicyTagInfo> expectedMatches =
        Map.of(
            "email_field", new PolicyTagInfo("EMAIL", "policy_tag_email", "pii"),
            "phone_field", new PolicyTagInfo("PHONE", "policy_tag_phone", "pii"));

    TableColumnsInfoTypes expectedNoMatches = new TableColumnsInfoTypes(
            TableSpec.fromSqlString("p.d.t"),
            Map.of("address_field", "STREET_ADDRESS")
            );

    assertEquals(expectedMatches, actual.x());
    assertEquals(expectedNoMatches, actual.y());
  }

  @Test
  public void testLookup_defaultDomain() {

    TableColumnsInfoTypes tableColumnsInfoTypes =
        new TableColumnsInfoTypes(
            TableSpec.fromSqlString("p.d.t"),
            Map.of(
                "email_field", "EMAIL",
                "phone_field", "PHONE"));

    Map<DatasetDomainMapKey, String> datasetDomainMapKeyStringMap =
        Map.of(new DatasetDomainMapKey("ppp", "ddd"), "domain_test");

    Map<InfoTypePolicyTagMapKey, InfoTypePolicyTagMapValue>
        infoTypePolicyTagMap =
            Map.of(
                new InfoTypePolicyTagMapKey("EMAIL", "eu", "default_domain"),
                new InfoTypePolicyTagMapValue("policy_tag_email", "pii"),
                new InfoTypePolicyTagMapKey("PHONE", "eu", "default_domain"),
                new InfoTypePolicyTagMapValue("policy_tag_phone", "pii"));

    Tuple<Map<String, PolicyTagInfo>, TableColumnsInfoTypes> actual =
        Tagger.lookupPolicyTags(
            tableColumnsInfoTypes,
            "EU",
            datasetDomainMapKeyStringMap,
            new HashMap<>(),
            "default_domain",
            infoTypePolicyTagMap);

    Map<String, PolicyTagInfo> expected =
        Map.of(
            "email_field", new PolicyTagInfo("EMAIL", "policy_tag_email", "pii"),
            "phone_field", new PolicyTagInfo("PHONE", "policy_tag_phone", "pii"));

    assertEquals(expected, actual.x());

    // no no-matches expected
    assertEquals(0, actual.y().columnsInfoType().size());
  }
  @Test
  public void testComputeFinalInfoType (){

    // Without other info types
    Assert.assertEquals(
            "EMAIL",
            Tagger.computeFinalInfoType("EMAIL",
                    List.of(),
                    false));
    assertEquals(
            "EMAIL",
            Tagger.computeFinalInfoType("EMAIL",
                    List.of(),
                    true));
    assertEquals(
            "EMAIL",
            Tagger.computeFinalInfoType("EMAIL",
                    null,
                    true));
    assertEquals(
            null,
            Tagger.computeFinalInfoType(null,
                    null,
                    true));

    // With 1 other info types and main info type
    assertEquals(
            "EMAIL",
            Tagger.computeFinalInfoType("EMAIL",
                    List.of(new DlpOtherInfoTypeMatch("PHONE", 100)),
                    false));
    assertEquals(
            "EMAIL",
            Tagger.computeFinalInfoType("EMAIL",
                    List.of(new DlpOtherInfoTypeMatch("PHONE",100)),
                    true));

    // With 1 other info types and no main info type with promoteDlpOtherMatches
    assertEquals(
            "PHONE",
            Tagger.computeFinalInfoType("",
                    List.of(new DlpOtherInfoTypeMatch("PHONE",100)),
                    true));
    assertEquals(
            "PHONE",
            Tagger.computeFinalInfoType(null,
                    List.of(new DlpOtherInfoTypeMatch("PHONE", 100)),
                    true));

    // With 1 other info types and no main info type without promoteDlpOtherMatches
    assertEquals(
            "",
            Tagger.computeFinalInfoType("",
                    List.of(new DlpOtherInfoTypeMatch("PHONE",100)),
                    false));
    assertEquals(
            null,
            Tagger.computeFinalInfoType(null,
                    List.of(new DlpOtherInfoTypeMatch("PHONE",100)),
                    false));

    // With 2 other info types and no main info type with promoteDlpOtherMatches
    assertEquals(
            "MIXED",
            Tagger.computeFinalInfoType("",
                    List.of(new DlpOtherInfoTypeMatch("PHONE",100), new DlpOtherInfoTypeMatch("IP",100)),
                    true));
    assertEquals(
            "MIXED",
            Tagger.computeFinalInfoType(null,
                    List.of(new DlpOtherInfoTypeMatch("PHONE",100), new DlpOtherInfoTypeMatch("IP",100)),
                    true));


  }

  @Test
  public void testComputeLabels(){

    TablePolicyTags tablePolicyTags = new TablePolicyTags(
            TableSpec.fromSqlString("p.d.t"),
            Map.of("email", new PolicyTagInfo("EMAIL", "email_policy_id", "PII"))
    );

    Map<String, InfoTypeInfo> infoTypeMap = Map.of(
            "EMAIL", new InfoTypeInfo("PII", List.of(new ResourceLabel("dg_pii", "yes"), new ResourceLabel("dg_high", "yes"))),
            "ADDRESS", new InfoTypeInfo("Location", List.of(new ResourceLabel("dg_location", "yes"), new ResourceLabel("dg_low", "yes")))
    );

    Map<String, String> actual = Tagger.generateTableLabelsFromDlpFindings(tablePolicyTags, infoTypeMap);
    Map<String, String> expected = Map.of("dg_pii", "yes",
            "dg_high", "yes"
            );

    assertEquals(expected, actual);
  }
}
