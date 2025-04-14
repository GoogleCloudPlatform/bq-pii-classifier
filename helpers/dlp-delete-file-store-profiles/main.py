from google.cloud import dlp_v2
import argparse
import time
import requests
import google.auth.transport.requests
from google.auth import default
from google.cloud import storage
from google.api_core import exceptions
import re

def extract_tag_binding_names(json_response):
    """
    Extracts a list of tagValue strings from the provided JSON response.

    Args:
        json_response: A dictionary representing the JSON response from the API.

    Returns:
        A list of strings, where each string is a tagValue.
    """
    tag_values = []
    if isinstance(json_response, dict) and "tagBindings" in json_response:
        for binding in json_response["tagBindings"]:
            if isinstance(binding, dict) and "name" in binding:
                tag_values.append(binding["name"])
    return tag_values

def list_bucket_tag_bindings(location, parent):

    try:
        # 1. Obtain Default Credentials with the 'storage.readonly' scope
        credentials, project_id = default(
            scopes=["https://www.googleapis.com/auth/cloud-platform.read-only"]
        )
        request = google.auth.transport.requests.Request()
        credentials.refresh(request)
        headers = {"Authorization": "Bearer " + credentials.token}

        # 2. Construct the API URL
        api_url = f"https://{location}-cloudresourcemanager.googleapis.com/v3/tagBindings?alt=json&parent={parent}"

        # 3. Make the Authenticated GET Request
        response = requests.get(api_url, headers=headers)
        response.raise_for_status()

        # 4. Parse the JSON Response
        json_data = response.json()
        return extract_tag_binding_names(json_data)


    except Exception as e:
        print(f"Error during GET API request: {e}")

def delete_bucket_tag_bindings(location, tag_binding_name):

    try:
        # 1. Obtain Default Credentials with the 'storage.readonly' scope
        credentials, project_id = default(
            scopes=["https://www.googleapis.com/auth/cloud-platform.read-only"]
        )
        request = google.auth.transport.requests.Request()
        credentials.refresh(request)
        headers = {"Authorization": "Bearer " + credentials.token}

        # 2. Construct the API URL
        api_url = f" https://{location}-cloudresourcemanager.googleapis.com/v3/{tag_binding_name}"

        # 3. Make the Authenticated DELETE Request
        response = requests.delete(api_url, headers=headers)
        response.raise_for_status()

        # 4. Parse the JSON Response
        json_response = response.json()

    except Exception as e:
        print(f"Error during DELETE API request: {e}")

def delete_bucket_labels_matching_regex(project_id, bucket_name, label_key_regex):
    """
    Deletes labels from a Cloud Storage bucket where the label key matches a regex.

    Args:
        project_id (str): The ID of the Google Cloud project where the bucket resides.
        bucket_name (str): The name of the Cloud Storage bucket.
        label_key_regex (str): A regular expression to match against label keys.
    """

    storage_client = storage.Client(project=project_id)

    try:
        bucket = storage_client.get_bucket(bucket_name)

        if bucket.labels:
            labels_to_keep = {}
            labels_deleted = False
            for key, value in bucket.labels.items():
                if re.match(label_key_regex, key):
                    print(f"Deleting label with key: {key} from bucket: gs://{bucket_name}")
                    labels_deleted = True
                else:
                    labels_to_keep[key] = value

            if labels_deleted:
                bucket.labels = labels_to_keep
                bucket.update()
                print(f"Successfully deleted labels matching regex '{label_key_regex}' from bucket: gs://{bucket_name}")
            else:
                print(f"No labels found matching regex '{label_key_regex}' in bucket: gs://{bucket_name}")

        else:
            print(f"Bucket gs://{bucket_name} has no labels to delete.")

    except Exception as e:
        print(f"An unexpected error occurred while deleting labels from bucket gs://{bucket_name}: {e}")


def reset_testing_bucket(parent, *regions, project=None, labels_regex=None):
    """Deletes all file store data profiles, tags and labels of a bucket in the specified regions and optionally a project.

    Args:
        parent: The DLP parent resource in the format "organizations/<number>" or "projects/<project id>".
        regions: A list of DLP regions to process.
        project: (Optional) The specific Google Cloud project ID to filter file store profiles by.
                 If None, profiles from all projects within the parent will be considered.
                 :param labels_regex: A regex for the bucket labels to be deleted
    """
    client = dlp_v2.DlpServiceClient()

    for region in regions:
        regional_parent = f"{parent}/locations/{region}"
        list_filter = ""
        if project:
            list_filter = f"project_id = {project}"

        try:
            # List data profiles in the region, optionally filtered by project
            request = dlp_v2.ListFileStoreDataProfilesRequest(
                parent=regional_parent,
                filter=list_filter,
            )
            profiles = client.list_file_store_data_profiles(request=request)

            for profile in profiles:
                print(f"Deleting tags ..")

                bucket_resource_name = f"//storage.googleapis.com/projects/_/buckets/{profile.file_store_path.removeprefix("gs://")}"
                tag_names = list_bucket_tag_bindings(region, bucket_resource_name)
                print(tag_names)
                for tag_name in tag_names:
                    delete_bucket_tag_bindings(region, tag_name)

                print(f"Deleting labels ..")
                delete_bucket_labels_matching_regex(project, profile.file_store_path.removeprefix("gs://"), labels_regex)

                print(f"Deleting dlp profile ..")
                # for rate limiting
                time.sleep(1)
                client.delete_file_store_data_profile(
                    request=dlp_v2.DeleteFileStoreDataProfileRequest(name=profile.name)
                )

        except Exception as e:
            print(f"Error listing file store data profiles in {region}: {e}")


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Delete file store data profiles from DLP by region and optionally project.")
    parser.add_argument("dlp_parent", help="organizations/<number> or projects/<project id>")
    parser.add_argument("regions", nargs="+", help="The DLP regions where file store profiles are to be deleted")
    parser.add_argument(
        "--project",
        help="Optional: The specific Google Cloud project ID to filter file store profiles by.",
        default=None,
    )
    parser.add_argument(
        "--labels_regex",
        help="Optional: A regex for the bucket labels to be deleted.",
        default=".*",
    )
    args = parser.parse_args()
    reset_testing_bucket(args.dlp_parent, *args.regions, project=args.project, labels_regex=args.labels_regex)