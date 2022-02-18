/*
 * Copyright 2022 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     https://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

package com.google.cloud.pso.bq_pii_classifier.functions.dispatcher;


import com.google.cloud.pso.bq_pii_classifier.entities.NonRetryableApplicationException;
import com.google.cloud.pso.bq_pii_classifier.entities.TableOperationRequest;
import com.google.cloud.pso.bq_pii_classifier.services.BigQueryServiceImpl;
import com.google.cloud.pso.bq_pii_classifier.services.DlpResultsScannerImpl;
import com.google.cloud.pso.bq_pii_classifier.services.PubSubPublishResults;
import com.google.cloud.pso.bq_pii_classifier.services.PubSubServiceImpl;
import com.google.cloud.pso.bq_pii_classifier.services.TableOpsRequestFailedPubSubMessage;
import com.google.cloud.pso.bq_pii_classifier.services.TableOpsRequestSuccessPubSubMessage;
import com.google.common.collect.Lists;
import org.junit.Before;
import org.junit.Test;
import org.junit.runner.RunWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.MockitoJUnitRunner;

import java.io.IOException;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.List;
import java.util.stream.Collectors;

import static org.junit.Assert.assertEquals;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.Mockito.lenient;
import static org.mockito.Mockito.mock;

@RunWith(MockitoJUnitRunner.class)
public class DispatcherTest {

    @Mock
    DlpResultsScannerImpl dlpResultsService;
    @Mock BigQueryServiceImpl bqServiceMock;
    @Mock DispatcherConfig config = new DispatcherConfig(
            "testProjectId",
            "testComputeRegionId",
            "testDataRegionId",
            "testTaggerTopic"
    );
    @Mock String runId = "R-testxxxxxxx";

    @InjectMocks Dispatcher function;

    @Before
    public void setUp() throws IOException, NonRetryableApplicationException, InterruptedException {

        // mock dlpResultsService

        // use lenient() to disable strict stubbing. Mockito detects that the stubs are not used by they actually are!
        lenient().when(dlpResultsService.listDatasets("p1")).thenReturn(
                Arrays.asList("p1.d1","p1.d2")
        );
        lenient().when(dlpResultsService.listDatasets("p2")).thenReturn(
                Arrays.asList("p2.d1","p2.d2")
        );

        // list p1 tables
        lenient().when(dlpResultsService.listTables("p1", "d1")).thenReturn(
                Arrays.asList("p1.d1.t1", "p1.d1.t2")
        );

        lenient().when(dlpResultsService.listTables("p1", "d2")).thenReturn(
                Arrays.asList("p1.d2.t1", "p1.d2.t2")
        );

        // list p2 tables
        lenient().when(dlpResultsService.listTables("p2", "d1")).thenReturn(
                Arrays.asList("p2.d1.t1", "p2.d1.t2")
        );

        lenient().when(dlpResultsService.listTables("p2", "d2")).thenReturn(
                Arrays.asList("p2.d2.t1")
        );

        // Mock bqService
        lenient().when(bqServiceMock.getDatasetLocation(anyString(), anyString())).thenReturn("supported-region");
        lenient().when(bqServiceMock.getDatasetLocation("p2", "d2")).thenReturn("unsupported-region");


    }

    @Test
    public void testDispatcher_withTables () throws IOException, NonRetryableApplicationException, InterruptedException {

        BigQueryScope bigQueryScope = new BigQueryScope(
                Arrays.asList("p1", "p2"),
                Arrays.asList("p1.d2"), // should have no effect
                new ArrayList<>(),
                Arrays.asList("p1.d1.t1", "p1.d1.t2"),
                new ArrayList<>()
        );

        List<String> expectedOutput = Lists.newArrayList("p1.d1.t1", "p1.d1.t2");
        List<String> actualOutput = testWithInput(bigQueryScope);

        assertEquals(expectedOutput, actualOutput);
    }

//    @Test
//    public void testDispatcher_withDatasets () throws IOException {
//
//        String jsonPayLoad = "{\"tablesInclude\":\"\""
//                + ",\"tablesExclude\":\"p1.d1.t1\""
//                + ",\"datasetsInclude\":\"p1.d1, p1.d2\""
//                + ",\"datasetsExclude\":\"\""
//                + ",\"projectsInclude\":\"p2\"" // should have no effect
//                + "}";
//
//        List<String> expectedOutput = Lists.newArrayList("p1.d1.t2", "p1.d2.t1", "p1.d2.t2");
//        List<String> actualOutput = testWithInput(jsonPayLoad);
//
//        assertEquals(expectedOutput, actualOutput);
//    }
//
//    @Test
//    public void testDispatcher_withProjects () throws IOException {
//
//        String jsonPayLoad = "{\"tablesInclude\":\"\""
//                + ",\"tablesExclude\":\"p1.d2.t1\""
//                + ",\"datasetsInclude\":\"\""
//                + ",\"datasetsExclude\":\"p1.d1\""
//                + ",\"projectsInclude\":\"p1, p2\"" // should have no effect
//                + "}";
//
//        List<String> expectedOutput = Lists.newArrayList("p1.d2.t2", "p2.d1.t1", "p2.d1.t2");
//        List<String> actualOutput = testWithInput(jsonPayLoad);
//
//        assertEquals(expectedOutput, actualOutput);
//    }

    private List<String> testWithInput (BigQueryScope bigQueryScope) throws IOException, NonRetryableApplicationException, InterruptedException {

        //Dispatcher function = new Dispatcher(envMock, bqServiceMock, cloudTasksServiceMock);
        PubSubPublishResults results = function.execute(bigQueryScope);

        PubSubServiceImpl pubSubServiceMock = mock(PubSubServiceImpl.class);
        lenient().when(pubSubServiceMock.publishTableOperationRequests(anyString(), anyString(), any())).thenReturn(
                new PubSubPublishResults(
                        Arrays.asList(
                                new TableOpsRequestSuccessPubSubMessage(
                                        new TableOperationRequest("p1.d1.t1", "runId", "trackingId"),
                                        "publishedMessageId"
                                ),
                                new TableOpsRequestSuccessPubSubMessage(
                                        new TableOperationRequest("p1.d1.t2", "runId", "trackingId"),
                                        "publishedMessageId"
                                )
                        ),
                        Arrays.asList(
                                new TableOpsRequestFailedPubSubMessage(
                                        new TableOperationRequest("","",""),
                                        new Exception("test fail message")
                                )
                        )
                ));

        return results.getSuccessMessages().stream().map(x -> x.getMsg().getTableSpec()).collect(Collectors.toList());
    }
}