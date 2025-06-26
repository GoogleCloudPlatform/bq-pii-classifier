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
import com.google.api.gax.retrying.RetrySettings;
import com.google.cloud.bigquery.BigQuery;
import com.google.cloud.bigquery.BigQueryOptions;
import com.google.cloud.bigquery.Table;
import com.google.cloud.oss.solutions.annotations.entities.TableSpec;
import com.google.cloud.resourcemanager.v3.DeleteTagBindingMetadata;
import com.google.cloud.resourcemanager.v3.DeleteTagBindingRequest;
import com.google.cloud.resourcemanager.v3.ListTagBindingsRequest;
import com.google.cloud.resourcemanager.v3.TagBinding;
import com.google.cloud.resourcemanager.v3.TagBindingsClient;
import com.google.cloud.resourcemanager.v3.TagBindingsSettings;
import com.google.cloud.storage.Bucket;
import com.google.cloud.storage.Storage;
import com.google.cloud.storage.StorageOptions;
import com.google.common.base.VerifyException;
import com.google.protobuf.Empty;
import java.io.IOException;
import java.util.concurrent.ExecutionException;
import org.threeten.bp.Duration;

/**
 * Implementation of the TagsService with improved encapsulation and dependency injection.
 */
public class TagsServiceImpl implements TagsService {

    private final Storage storage;
    private final TagBindingsClientFactory tagBindingsClientFactory;
    private final BigQueryProvider bigQueryProvider;

    public TagsServiceImpl() {
        this.storage = StorageOptions.newBuilder().build().getService();
        this.tagBindingsClientFactory = new TagBindingsClientFactory();
        this.bigQueryProvider = new BigQueryProvider(
                RetrySettings.newBuilder()
                .setInitialRetryDelay(Duration.ofSeconds(1))
                .setRetryDelayMultiplier(2)
                .setMaxRetryDelay(Duration.ofSeconds(10))
                .setTotalTimeout(Duration.ofSeconds(30))
                .build()
        );
    }

    /**
     * Deletes a specific tag binding from a GCS bucket.
     *
     * @param bucketName The name of the GCS bucket.
     * @param tagValueId The id of the tag value to delete the binding for.
     */
    @Override
    public void deleteTagBindingFromBucket(String bucketName, String tagValueId)
            throws ParentNotFoundException, IOException, TagBindingNotFoundException {
        // Make sure the bucket still exists and get its location
        Bucket bucket = getBucket(bucketName);
        String gcsLocation = bucket.getLocation();
        String parent = "//storage.googleapis.com/projects/_/buckets/" + bucketName;
        deleteTagBinding(parent, tagValueId, gcsLocation);
    }

    /**
     * Deletes a specific tag binding from a BigQuery table.
     *
     * @param bqOperationProject The project to perform the operation.
     * @param tableSpec          The table specifications.
     * @param tableRegion        The region of the table.
     * @param tagValueId         The tag value id to delete.
     */
    @Override
    public void deleteTagBindingFromTable(String bqOperationProject, TableSpec tableSpec, String tableRegion, String tagValueId)
            throws ParentNotFoundException, TagBindingNotFoundException, IOException {

        // 2. Check if table exists
        checkTableExists(bqOperationProject, tableSpec);

        String parent = String.format("//bigquery.googleapis.com/projects/%s/datasets/%s/tables/%s",
                tableSpec.project(),
                tableSpec.dataset(),
                tableSpec.table());

        deleteTagBinding(parent, tagValueId, tableRegion);
    }

    private void deleteTagBinding(String parentResource, String tagValueId, String region) throws IOException, TagBindingNotFoundException {
        try (TagBindingsClient tagBindingsClient = tagBindingsClientFactory.create(region)) {
            String tagBindingNameToDelete = findTagBindingName(tagBindingsClient, parentResource, tagValueId);
            if (tagBindingNameToDelete != null) {
                deleteTagBindingOperation(tagBindingsClient, tagBindingNameToDelete);
            } else {
                String msg = String.format("Couldn't find tag '%s' attached to the resource '%s'", tagValueId, parentResource);
                throw new TagBindingNotFoundException(msg);
            }
        }
    }

    private Bucket getBucket(String bucketName) throws ParentNotFoundException {
        Bucket bucket = storage.get(bucketName);
        if (bucket == null) {
            String msg = String.format("Bucket '%s' is not found or caller has no permissions.", bucketName);
            throw new ParentNotFoundException(msg);
        }
        return bucket;
    }

    private void checkTableExists(String bqOperationProject, TableSpec tableSpec) throws ParentNotFoundException {
        BigQuery bigQuery = bigQueryProvider.getBigQuery(bqOperationProject);
        Table table = bigQuery.getTable(tableSpec.toTableId());
        if (table == null) {
            String msg = String.format("Table '%s' not found.", tableSpec.toSqlString());
            throw new ParentNotFoundException(msg);
        }
    }


    private String findTagBindingName(TagBindingsClient tagBindingsClient, String parentResource, String tagValueId) throws IOException {
        ListTagBindingsRequest listRequest = ListTagBindingsRequest.newBuilder().setParent(parentResource).build();
        TagBindingsClient.ListTagBindingsPagedResponse response = tagBindingsClient.listTagBindings(listRequest);
        for (TagBinding tagBinding : response.iterateAll()) {
            if (tagBinding.getTagValue().equals(tagValueId)) {
                return tagBinding.getName();
            }
        }
        return null;
    }

    private void deleteTagBindingOperation(TagBindingsClient tagBindingsClient, String tagBindingNameToDelete) {
        DeleteTagBindingRequest deleteRequest =
                DeleteTagBindingRequest.newBuilder().setName(tagBindingNameToDelete).build();
        OperationFuture<Empty, DeleteTagBindingMetadata> operation =
                tagBindingsClient.deleteTagBindingAsync(deleteRequest);
        try {
            operation.get();
        } catch (InterruptedException e) {
            Thread.currentThread().interrupt();
            throw new VerifyException("Error deleting tag binding: operation interrupted",e);
        } catch (ExecutionException e) {
            throw new VerifyException("Error deleting tag binding: operation failed",e);
        }
    }

    /**
     * Default implementation for TagBindingsClientFactory
     */
    public static class TagBindingsClientFactory {

        public TagBindingsClient create(String region) throws IOException {
            String regionalEndpoint = String.format("%s-cloudresourcemanager.googleapis.com:443", region);
            TagBindingsSettings tagBindingsSettings = TagBindingsSettings.newBuilder()
                    .setEndpoint(regionalEndpoint)
                    .build();
            return TagBindingsClient.create(tagBindingsSettings);
        }
    }

    /**
     * Default implementation for BigQuery provider
     */
    public static class BigQueryProvider {

        private final RetrySettings retrySettings;

        public BigQueryProvider(RetrySettings retrySettings) {
            this.retrySettings = retrySettings;
        }

        public BigQuery getBigQuery(String bqOperationProject) {
            return BigQueryOptions.newBuilder().setProjectId(bqOperationProject).setRetrySettings(retrySettings).build().getService();
        }
    }
}

