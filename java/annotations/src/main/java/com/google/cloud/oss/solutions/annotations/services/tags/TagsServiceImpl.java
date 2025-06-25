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

package com.google.cloud.oss.solutions.annotations.services.tags;

import com.google.api.gax.longrunning.OperationFuture;
import com.google.cloud.resourcemanager.v3.*;
import com.google.cloud.storage.Storage;
import com.google.cloud.storage.Bucket;
import com.google.cloud.storage.StorageOptions;
import com.google.protobuf.Empty;

import java.io.IOException;
import java.util.concurrent.ExecutionException;

public class TagsServiceImpl implements TagsService {

    private final Storage storage;

    public TagsServiceImpl() {
        this.storage = StorageOptions.newBuilder().build().getService();
    }


    /**
     * Deletes a specific tag binding from a GCS bucket.
     *
     * @param bucketName The name of the GCS bucket.
     * @param tagValueId The id of the tag value to delete the binding for.
     */
    public void deleteTagBinding(String bucketName, String tagValueId) throws ParentNotFoundException, IOException, TagBindingNotFoundException {

        // Make sure the bucket still exists and get its location
        Bucket bucket = storage.get(bucketName);
        if (bucket == null) {
            String msg = String.format("Bucket '%s' is not found or caller has no permissions.", bucketName);
            throw new ParentNotFoundException(msg);
        }

        String gcsLocation = bucket.getLocation();

        String regionalEndpoint = String.format("%s-cloudresourcemanager.googleapis.com:443", gcsLocation);

        TagBindingsSettings tagBindingsSettings = TagBindingsSettings.newBuilder()
                .setEndpoint(regionalEndpoint)
                .build();

        // Initialize the Resource Manager TagBindingsClient.
        try (TagBindingsClient tagBindingsClient = TagBindingsClient.create(tagBindingsSettings)) {

            String parent = "//storage.googleapis.com/projects/_/buckets/" + bucketName;

            // List the tag bindings for the bucket to find the one to delete.
            ListTagBindingsRequest listRequest = ListTagBindingsRequest.newBuilder().setParent(parent).build();
            TagBindingsClient.ListTagBindingsPagedResponse response = tagBindingsClient.listTagBindings(listRequest);

            String tagBindingNameToDelete = null;
            for (TagBinding tagBinding : response.iterateAll()) {
                if (tagBinding.getTagValue().equals(tagValueId)) {
                    tagBindingNameToDelete = tagBinding.getName();
                    break;
                }
            }

            if (tagBindingNameToDelete != null) {
                // The rest of the delete operation logic is unchanged.
                DeleteTagBindingRequest deleteRequest =
                        DeleteTagBindingRequest.newBuilder().setName(tagBindingNameToDelete).build();

                OperationFuture<Empty, DeleteTagBindingMetadata> operation =
                        tagBindingsClient.deleteTagBindingAsync(deleteRequest);

                try {
                    operation.get();
                } catch (InterruptedException | ExecutionException e) {
                    throw new RuntimeException(e);
                }

            } else {
                String msg = String.format("Couldn't find tag '%s' attached to bucket '%s'", tagValueId ,bucketName);
                throw new TagBindingNotFoundException(msg);
            }
        }
    }

}
