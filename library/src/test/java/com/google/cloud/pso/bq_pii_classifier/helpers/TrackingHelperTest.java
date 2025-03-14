package com.google.cloud.pso.bq_pii_classifier.helpers;

import static org.junit.Assert.assertEquals;
import org.junit.Test;

public class TrackingHelperTest {
    @Test
    public void  extractTrackingIdFromJobName(){
        assertEquals("9-9-9-9",
                TrackingHelper.extractTrackingIdFromJobName(String.format("//projects/locations/dlpJobs/i-9-9-9-9_1")));
    }
}
