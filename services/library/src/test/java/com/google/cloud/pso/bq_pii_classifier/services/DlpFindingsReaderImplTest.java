package com.google.cloud.pso.bq_pii_classifier.services;

import com.google.cloud.pso.bq_pii_classifier.services.findings.DlpFindingsReaderImpl;
import org.junit.Assert;
import org.junit.Test;

import java.util.List;

import static org.junit.Assert.assertEquals;

public class DlpFindingsReaderImplTest {

    @Test
    public void testComputeFinalInfoType (){

        // Without other info types
        Assert.assertEquals(
                "EMAIL",
                DlpFindingsReaderImpl.computeFinalInfoType("EMAIL",
                        List.of(),
                        false));
        assertEquals(
                "EMAIL",
                DlpFindingsReaderImpl.computeFinalInfoType("EMAIL",
                        List.of(),
                        true));
        assertEquals(
                "EMAIL",
                DlpFindingsReaderImpl.computeFinalInfoType("EMAIL",
                        null,
                        true));
        assertEquals(
                null,
                DlpFindingsReaderImpl.computeFinalInfoType(null,
                        null,
                        true));

        // With 1 other info types and main info type
        assertEquals(
                "EMAIL",
                DlpFindingsReaderImpl.computeFinalInfoType("EMAIL",
                        List.of("PHONE"),
                        false));
        assertEquals(
                "EMAIL",
                DlpFindingsReaderImpl.computeFinalInfoType("EMAIL",
                        List.of("PHONE"),
                        true));

        // With 1 other info types and no main info type with promoteDlpOtherMatches
        assertEquals(
                "PHONE",
                DlpFindingsReaderImpl.computeFinalInfoType("",
                        List.of("PHONE"),
                        true));
        assertEquals(
                "PHONE",
                DlpFindingsReaderImpl.computeFinalInfoType(null,
                        List.of("PHONE"),
                        true));

        // With 1 other info types and no main info type without promoteDlpOtherMatches
        assertEquals(
                "",
                DlpFindingsReaderImpl.computeFinalInfoType("",
                        List.of("PHONE"),
                        false));
        assertEquals(
                null,
                DlpFindingsReaderImpl.computeFinalInfoType(null,
                        List.of("PHONE"),
                        false));

        // With 2 other info types and no main info type with promoteDlpOtherMatches
        assertEquals(
                "MIXED",
                DlpFindingsReaderImpl.computeFinalInfoType("",
                        List.of("PHONE", "IP"),
                        true));
        assertEquals(
                "MIXED",
                DlpFindingsReaderImpl.computeFinalInfoType(null,
                        List.of("PHONE", "IP"),
                        true));


    }
}
