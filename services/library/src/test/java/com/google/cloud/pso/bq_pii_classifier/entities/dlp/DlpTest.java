package com.google.cloud.pso.bq_pii_classifier.entities.dlp;

import com.google.cloud.pso.bq_pii_classifier.entities.dlp.DataProfilePubSubMessage;
import com.google.protobuf.InvalidProtocolBufferException;
import org.junit.Test;

import java.util.Base64;

import static org.junit.Assert.assertEquals;

public class DlpTest {

    public DlpTest(){}

    @Test
    public void testParseFromByteArray() throws InvalidProtocolBufferException {
        // Example byte string as we receive it in PubSub from DLP
        String base64String = "EAEaTgpCb3JnYW5pemF0aW9ucy8xMjMvbG9jYXRpb25zL2V1cm9wZS13ZXN0My9maWxlU3RvcmVEYXRhUHJvZmlsZXMvMTIzMghnczovL3h5eg==";
        byte [] byteArray = Base64.getDecoder().decode(base64String);

        // Parse the byte array into a MyMessage object
        DataProfilePubSubMessage message = DataProfilePubSubMessage.parseFrom(byteArray);

        // Assert the parsed values
        assertEquals("organizations/123/locations/europe-west3/fileStoreDataProfiles/123", message.getFileStoreProfile().getName());
        assertEquals("gs://xyz", message.getFileStoreProfile().getFileStorePath());
    }
}
