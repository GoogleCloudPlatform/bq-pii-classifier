package com.google.cloud.pso.bq_pii_classifier.functions.helpers;

import com.google.cloud.pso.bq_pii_classifier.helpers.TrackingHelper;
import org.junit.Test;

import static org.junit.Assert.assertEquals;

public class TrackingHelperTest {

    @Test
    public void  extractTrackingIdFromJobName(){
        assertEquals("1748425779458-I-2026f88e-82f4-44c7-954d-d8e396f01b73_1",
                TrackingHelper.extractTrackingIdFromJobName(String.format("//projects/locations/dlpJobs/i-1748425779458-I-2026f88e-82f4-44c7-954d-d8e396f01b73_1")));
    }
}
