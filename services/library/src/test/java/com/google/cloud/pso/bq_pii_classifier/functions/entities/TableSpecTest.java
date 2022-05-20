package com.google.cloud.pso.bq_pii_classifier.functions.entities;

import com.google.cloud.pso.bq_pii_classifier.entities.TableSpec;
import com.google.cloud.pso.bq_pii_classifier.helpers.Utils;
import com.google.privacy.dlp.v2.Table;
import org.junit.Test;

import static org.junit.Assert.assertEquals;

public class TableSpecTest {

    @Test
    public void fromFullResource() {

        String input = "//bigquery.googleapis.com/projects/test_project/datasets/test_dataset/tables/test_table";
        TableSpec expected = new TableSpec("test_project", "test_dataset", "test_table");
        TableSpec actual = TableSpec.fromFullResource(input);

        assertEquals(expected, actual);
    }


}
