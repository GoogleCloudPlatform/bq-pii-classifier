/*
 *
 *  Copyright 2025 Google LLC
 *
 *  Licensed under the Apache License, Version 2.0 (the "License");
 *  you may not use this file except in compliance with the License.
 *  You may obtain a copy of the License at
 *
 *       https://www.apache.org/licenses/LICENSE-2.0
 *
 *  Unless required by applicable law or agreed to in writing, software
 *  distributed under the License is distributed on an "AS IS" BASIS,
 *  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or
 *  implied.
 *  See the License for the specific language governing permissions and
 *  limitations under the License.
 *
 */

package com.google.cloud.oss.solutions.annotations.entities.dlp;

import static org.junit.Assert.assertEquals;

import com.google.protobuf.InvalidProtocolBufferException;
import java.util.Base64;
import org.junit.Test;

/** Unit tests for the Dlp entity. */
public class DlpTest {

  /**
   * Tests the parsing of a byte array into a DataProfilePubSubMessage object.
   *
   * @throws InvalidProtocolBufferException if the byte array cannot be parsed.
   */
  @Test
  public void testParseFromByteArray() throws InvalidProtocolBufferException {
    // Example byte string as we receive it in PubSub from DLP
    String base64String =
        "EAEaTgpCb3JnYW5pemF0aW9ucy8xMjMvbG9jYXRpb25zL2V1cm9wZS13ZXN0My9maWxlU3RvcmVEYXRhUHJvZmlsZXMvMTIzMghnczovL3h5eg==";
    byte[] byteArray = Base64.getDecoder().decode(base64String);

    // Parse the byte array into a MyMessage object
    DataProfilePubSubMessage message = DataProfilePubSubMessage.parseFrom(byteArray);

    // Assert the parsed values
    assertEquals(
        "organizations/123/locations/europe-west3/fileStoreDataProfiles/123",
        message.getFileStoreProfile().getName());
    assertEquals("gs://xyz", message.getFileStoreProfile().getFileStorePath());
  }
}
