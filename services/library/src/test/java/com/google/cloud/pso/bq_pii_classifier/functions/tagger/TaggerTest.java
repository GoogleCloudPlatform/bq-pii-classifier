package com.google.cloud.pso.bq_pii_classifier.functions.tagger;

import com.google.cloud.pso.bq_pii_classifier.entities.PolicyTagInfo;
import com.google.cloud.pso.bq_pii_classifier.entities.TableColumnsInfoTypes;
import com.google.cloud.pso.bq_pii_classifier.entities.TableSpec;
import org.junit.jupiter.api.Test;

import java.util.HashMap;
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
                "phone_field", "PHONE"));

    Map<DatasetDomainMapKey, String> datasetDomainMapKeyStringMap =
        Map.of(new DatasetDomainMapKey("p", "d"), "domain_test");

    Map<InfoTypePolicyTagMapKey, InfoTypePolicyTagMapValue>
        infoTypePolicyTagMap =
            Map.of(
                new InfoTypePolicyTagMapKey("EMAIL", "eu", "domain_test"),
                new InfoTypePolicyTagMapValue("policy_tag_email", "pii"),
                new InfoTypePolicyTagMapKey("PHONE", "eu", "domain_test"),
                new InfoTypePolicyTagMapValue("policy_tag_phone", "pii"));

    Map<String, PolicyTagInfo> actual =
        Tagger.lookupPolicyTags(
            tableColumnsInfoTypes,
            "eu",
            datasetDomainMapKeyStringMap,
            new HashMap<>(),
            "default_domain",
            infoTypePolicyTagMap);

    Map<String, PolicyTagInfo> expected =
        Map.of(
            "email_field", new PolicyTagInfo("EMAIL", "policy_tag_email", "pii"),
            "phone_field", new PolicyTagInfo("PHONE", "policy_tag_phone", "pii"));

    assertEquals(expected, actual);
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

    Map<String, PolicyTagInfo> actual =
        Tagger.lookupPolicyTags(
            tableColumnsInfoTypes,
            "eu",
            datasetDomainMapKeyStringMap,
            new HashMap<>(),
            "default_domain",
            infoTypePolicyTagMap);

    Map<String, PolicyTagInfo> expected =
        Map.of(
            "email_field", new PolicyTagInfo("EMAIL", "policy_tag_email", "pii"),
            "phone_field", new PolicyTagInfo("PHONE", "policy_tag_phone", "pii"));

    assertEquals(expected, actual);
  }
}
