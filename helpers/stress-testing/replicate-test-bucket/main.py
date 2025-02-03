from google.cloud import storage
import concurrent.futures
import argparse
import time


def replicate_bucket(project_id, location, source_bucket_name, destination_bucket_name):
    """replicates a bucket."""
    try:
        storage_client = storage.Client(project=project_id)
        source_bucket = storage_client.bucket(source_bucket_name)
        destination_bucket = storage_client.bucket(destination_bucket_name)
        destination_bucket.iam_configuration.uniform_bucket_level_access_enabled = True
        destination_bucket.create(location=location)
        # for rate limiting
        time.sleep(1)
        print(f"- Bucket {destination_bucket_name} created.")

        # Copy all blobs from source to destination
        blobs = source_bucket.list_blobs()  # Efficient listing
        for blob in blobs:
            new_blob = destination_bucket.copy_blob(blob, destination_bucket, blob.name) # copy blob with the same name
            # print(f"    -- Blob {blob.name} copied to {destination_bucket_name}")
        return None  # Return None for success (no error)
    except Exception as e:
        error_message = f"- Error copying {source_bucket_name} to {destination_bucket_name}: {e}"
        print(error_message)  # Print error immediately
        return error_message  # Return error message


def copy_buckets_parallel(project_id, location, source_bucket_name, replica_prefix, num_replicas, start_number, max_workers=20):
    """Copies buckets in parallel and reports errors."""
    destination_bucket_names = [f"{replica_prefix}-{start_number + i}" for i in range(num_replicas)]
    futures = []
    errors = []

    with concurrent.futures.ThreadPoolExecutor(max_workers=max_workers) as executor:
        for dest_name in destination_bucket_names:
            future = executor.submit(replicate_bucket, project_id, location, source_bucket_name, dest_name)
            futures.append(future)

        # Wait for all futures to complete and collect results/errors
        for future, dest_name in zip(futures, destination_bucket_names): # associate future with bucket name
            error = future.result() #blocking call
            if error:
                errors.append(error)

    if errors:
        print("\n--- ERRORS REPORT ---")
        for error in errors:
            print(error)
        return False
    else:
        print("\nAll buckets copied successfully.")
        return True


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Copy a GCP bucket multiple times in parallel.")
    parser.add_argument("source_bucket", help="Name of the source bucket.")
    parser.add_argument("replica_prefix", help="Prefix for the replica bucket names.")
    parser.add_argument("-p", "--project", required=True,  help="GCP project ID.")
    parser.add_argument("-l", "--location", required=True, help="GCP bucket location (e.g., US, EU, us-central1).")
    parser.add_argument("-n", "--num_replicas", type=int, default=1, help="Number of replicas to create.")
    parser.add_argument("-s", "--start_number", type=int, default=1, help="Starting number for replica names.")
    parser.add_argument("-w", "--max_workers", type=int, default=20, help="Maximum number of worker threads.")


    args = parser.parse_args()

    copy_buckets_parallel(args.project, args.location, args.source_bucket, args.replica_prefix, args.num_replicas, args.start_number, args.max_workers)