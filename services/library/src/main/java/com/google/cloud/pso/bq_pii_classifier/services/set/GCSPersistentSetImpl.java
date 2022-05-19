package com.google.cloud.pso.bq_pii_classifier.services.set;

import com.google.cloud.storage.*;
import com.google.cloud.storage.Storage;
import com.google.cloud.storage.StorageOptions;

public class GCSPersistentSetImpl implements PersistentSet {

    private Storage storage;
    private String bucketName;

    public GCSPersistentSetImpl(String bucketName) {
        // Instantiates a client
        this.storage = StorageOptions.getDefaultInstance().getService();
        this.bucketName = bucketName;
    }

    @Override
    public void add(String key) {
        BlobId blobId = BlobId.of(bucketName, key);
        BlobInfo blobInfo = BlobInfo.newBuilder(blobId).build();
        storage.create(blobInfo);
    }

    @Override
    public boolean contains(String key) {
        BlobId blobId = BlobId.of(bucketName, key);
        Blob blob = storage.get(blobId);
        return blob != null;
    }
}
