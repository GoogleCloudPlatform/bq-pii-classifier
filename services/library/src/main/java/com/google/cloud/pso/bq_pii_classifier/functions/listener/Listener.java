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

package com.google.cloud.pso.bq_pii_classifier.functions.listener;

import com.google.cloud.pso.bq_pii_classifier.entities.NonRetryableApplicationException;
import com.google.cloud.pso.bq_pii_classifier.entities.Operation;
import com.google.cloud.pso.bq_pii_classifier.helpers.LoggingHelper;
import com.google.cloud.pso.bq_pii_classifier.helpers.TrackingHelper;
import com.google.cloud.pso.bq_pii_classifier.services.dlp.DlpService;
import com.google.cloud.pso.bq_pii_classifier.services.pubsub.PubSubPublishResults;
import com.google.cloud.pso.bq_pii_classifier.services.pubsub.PubSubService;
import com.google.cloud.pso.bq_pii_classifier.services.pubsub.FailedPubSubMessage;
import com.google.cloud.pso.bq_pii_classifier.services.pubsub.SuccessPubSubMessage;

import java.io.IOException;
import java.util.Arrays;

public class Listener {

    private static final Integer functionNumber = 3;

    private final LoggingHelper logger;

    private ListenerConfig config;
    //private DlpService dlpService;
    private PubSubService pubSubService;


    public Listener(ListenerConfig config, DlpService dlpService, PubSubService pubSubService){
        this.config = config;
       // this.dlpService = dlpService;
        this.pubSubService = pubSubService;

        logger = new LoggingHelper(
                Listener.class.getSimpleName(),
                functionNumber,
                config.getProjectId()
        );
    }

    public PubSubPublishResults execute(String dlpJobName, String trackingId) throws NonRetryableApplicationException, IOException, InterruptedException {

        logger.logFunctionStart(trackingId);

        logger.logInfoWithTracker(trackingId, String.format("Received DlpJobName %s", dlpJobName));

        // Calling DLP counts against the 600 requests per min and that leads to an increase in the back log
        // TODO: We comment all DLP operations for now. Consider dropping the listener function if auto dlp sends a job name for the table profile

        //DlpJob.JobState dlpJobState = dlpService.getJobState(dlpJobName);

//        if (dlpJobState != DlpJob.JobState.DONE) {
//            String msg = String.format("DLP Job '%s' state must be 'DONE'. Current state : '%s'. Function call will terminate. ",
//                    dlpJobName,
//                    dlpJobState);
//            logger.logSevereWithTracker(trackingId, msg);
//            // this shouldn't happen because DLP shouldn't send the message before teh job finishes. That's why it's NonRetryable
//            throw new NonRetryableApplicationException(msg);
//        }

//        BigQueryTable inspectedTable = dlpService.getInspectedTable(dlpJobName);
//        TableSpec tableSpec = new TableSpec(
//                inspectedTable.getProjectId(),
//                inspectedTable.getDatasetId(),
//                inspectedTable.getTableId()
//        );

        Operation taggerRequest = new Operation(
                dlpJobName,
                TrackingHelper.parseRunIdAsPrefix(trackingId),
                trackingId
        );

        PubSubPublishResults pubSubPublishResults = pubSubService.publishTableOperationRequests(
                config.getProjectId(),
                config.getTaggerTopicId(),
                Arrays.asList(taggerRequest)
        );

        for(FailedPubSubMessage msg: pubSubPublishResults.getFailedMessages()){
            String logMsg = String.format("Failed to publish this messages %s", msg.toString());
            logger.logWarnWithTracker(trackingId, logMsg);
        }

        for(SuccessPubSubMessage msg: pubSubPublishResults.getSuccessMessages()){
            String logMsg = String.format("Successfully publish this messages %s", msg.toString());
            logger.logInfoWithTracker(trackingId, logMsg);
        }

        logger.logFunctionEnd(trackingId);

        return pubSubPublishResults;
    }


}
