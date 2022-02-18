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

package com.google.cloud.pso.bq_pii_classifier.helpers;

import com.google.api.gax.rpc.ApiException;
import com.google.api.gax.rpc.ResourceExhaustedException;
import com.google.cloud.BaseServiceException;
import com.google.cloud.bigquery.BigQueryException;
import com.google.common.collect.Sets;
import io.grpc.Status;
import io.grpc.StatusRuntimeException;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;

import java.io.IOException;
import java.util.Set;

public class ControllerExceptionHelper {

    public static boolean isRetryableException(Exception ex){

        // add more Retryable Exceptions Here
        Set<Class> retryableExceptions = Sets.newHashSet(
                ResourceExhaustedException.class,
                IOException.class);

        Class exceptionClass = ex.getClass();

        // 1. Check if it's any type of rate limit exception. If so, retry.

        // Thrown by DLP
        if(StatusRuntimeException.class.isAssignableFrom(exceptionClass)){
            StatusRuntimeException statusRuntimeException = (StatusRuntimeException) ex;
            if (statusRuntimeException.getStatus().equals(Status.RESOURCE_EXHAUSTED)){
                return true;
            }
        }

        // Thrown by BigQuery
        if(BigQueryException.class.isAssignableFrom(exceptionClass)){
            BigQueryException bigQueryException = (BigQueryException) ex;
            // when hitting the concurrent interactive queries
            if (bigQueryException.getReason().equals("jobRateLimitExceeded")){
                return true;
            }
        }

        // BaseServiceException Thrown by BigQuery
        if(BaseServiceException.class.isAssignableFrom(exceptionClass)){
            BaseServiceException baseServiceException = (BaseServiceException) ex;
            if (baseServiceException.getCode() == 429){
                return true;
            }
        }

        // 2. check if the exception inherits (at any level) from any Retryable Exception that we explicitly define
        for(Class retryableExClass: retryableExceptions){
            if (retryableExClass.isAssignableFrom(exceptionClass)){
                return true;
            }
        }

        // 3. Check if it's any type of isRetryable. If so, retry.

        // Thrown by BigQuery:
        // Base class for all gcp service exceptions.
        // Check if it's a retryable BaseServiceException
        if (BaseServiceException.class.isAssignableFrom(exceptionClass)){
            BaseServiceException baseServiceException = (BaseServiceException) ex;
            return baseServiceException.isRetryable();
        }

        // Check if it's Retryable ApiException
        if (ApiException.class.isAssignableFrom(exceptionClass)){
            ApiException apiEx = (ApiException) ex;
            return apiEx.isRetryable();
        }

        // if not, log and ACK so that it's not retried
        return false;

    }

    public static ResponseEntity handleException(Exception ex, LoggingHelper logger, String trackingId){

        if(isRetryableException(ex)){

            logger.logRetryableExceptions(trackingId, ex);
            return new ResponseEntity(ex.getMessage(), HttpStatus.TOO_MANY_REQUESTS);

        }else{

            // if not, log and ACK so that it's not retried
            ex.printStackTrace();
            logger.logNonRetryableExceptions(trackingId, ex);
            return new ResponseEntity(ex.getMessage(), HttpStatus.OK);
        }
    }

}
