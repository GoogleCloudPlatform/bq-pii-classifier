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

package com.google.cloud.pso.bq_pii_classifier.functions.helpers;

import com.google.api.gax.rpc.ApiException;
import com.google.api.gax.rpc.ResourceExhaustedException;
import com.google.api.gax.rpc.StatusCode;
import com.google.cloud.pso.bq_pii_classifier.helpers.ControllerExceptionHelper;
import com.google.cloud.pso.bq_pii_classifier.helpers.LoggingHelper;
import io.grpc.Status;
import io.grpc.StatusRuntimeException;
import org.junit.Test;
import org.springframework.http.HttpStatus;

import javax.net.ssl.SSLException;

import static org.junit.Assert.assertEquals;

public class ControllerExceptionHelperTest {

    @Test
    public void testRetryableApiException() {
        LoggingHelper logger = new LoggingHelper(ControllerExceptionHelperTest.class.getSimpleName(), 0, "test");

        try {

            throw new ApiException(new Exception("Test Retryable ApiException"), new StatusCode() {
                @Override
                public Code getCode() {
                    return Code.RESOURCE_EXHAUSTED;
                }

                @Override
                public Object getTransportCode() {
                    return null;
                }
            }, true);

        } catch (Exception e) {

            assertEquals(
                    HttpStatus.TOO_MANY_REQUESTS,
                    ControllerExceptionHelper
                            .handleException(e, logger, "retryableTracker")
                            .getStatusCode()
                    );

        }

    }

    @Test
    public void testNonRetryableApiException() {
        LoggingHelper logger = new LoggingHelper(ControllerExceptionHelperTest.class.getSimpleName(), 0, "test");

        try {

            throw new ApiException(new Exception("Test Non Retryable ApiException"), new StatusCode() {
                @Override
                public Code getCode() {
                    return Code.UNAUTHENTICATED;
                }

                @Override
                public Object getTransportCode() {
                    return null;
                }
            }, false);

        } catch (Exception e) {

            assertEquals(
                    HttpStatus.OK,
                    ControllerExceptionHelper
                            .handleException(e, logger, "nonRetryableTracker")
                            .getStatusCode()
                    );

        }

    }

    @Test
    public void testRetryableIOException() {
        LoggingHelper logger = new LoggingHelper(ControllerExceptionHelperTest.class.getSimpleName(), 0, "test");

        try {

            throw new SSLException("Testing standard Retryable Exception");

        } catch (Exception e) {

            assertEquals(
                    HttpStatus.TOO_MANY_REQUESTS,
                    ControllerExceptionHelper
                            .handleException(e, logger, "retryableTracker")
                            .getStatusCode()
                    );

        }
    }

    @Test
    public void testRetryableRuntimeStatusResourceExhaustedException() {
        LoggingHelper logger = new LoggingHelper(ControllerExceptionHelperTest.class.getSimpleName(), 0, "test");

        try {

            throw new StatusRuntimeException(Status.RESOURCE_EXHAUSTED);

        } catch (Exception e) {

            assertEquals(
                    HttpStatus.TOO_MANY_REQUESTS,
                    ControllerExceptionHelper
                            .handleException(e, logger, "resourceExhaustedTracker")
                            .getStatusCode()
            );

        }
    }

    @Test
    public void testRetryableResourceExhaustedException() {
        LoggingHelper logger = new LoggingHelper(ControllerExceptionHelperTest.class.getSimpleName(), 0, "test");

        try {

            throw new ResourceExhaustedException("resource Exhausted Exception",
                    new Exception("resource Exhausted Exception"),
                    new StatusCode() {
                        @Override
                        public Code getCode() {
                            return Code.RESOURCE_EXHAUSTED;
                        }

                        @Override
                        public Object getTransportCode() {
                            return null;
                        }
                    },
                    true
                    );

        } catch (Exception e) {

            assertEquals(
                    HttpStatus.TOO_MANY_REQUESTS,
                    ControllerExceptionHelper
                            .handleException(e, logger, "resourceExhaustedTracker")
                            .getStatusCode()
            );

        }
    }


    @Test
    public void testNonRetryableException() {
        LoggingHelper logger = new LoggingHelper(ControllerExceptionHelperTest.class.getSimpleName(), 0, "test");

        try {

            throw new IndexOutOfBoundsException("Testing standard Non Retryable Exception");

        } catch (Exception e) {

            assertEquals(
                    HttpStatus.OK,
                    ControllerExceptionHelper
                            .handleException(e, logger, "nonRetryableTracker")
                            .getStatusCode()
                    );

        }

    }
}
