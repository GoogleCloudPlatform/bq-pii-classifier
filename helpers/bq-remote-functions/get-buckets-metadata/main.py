# /*
# * Copyright 2023 Google LLC
# *
# * Licensed under the Apache License, Version 2.0 (the "License");
# * you may not use this file except in compliance with the License.
# * You may obtain a copy of the License at
# *
# *     https://www.apache.org/licenses/LICENSE-2.0
# *
# * Unless required by applicable law or agreed to in writing, software
# * distributed under the License is distributed on an "AS IS" BASIS,
# * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# * See the License for the specific language governing permissions and
# * limitations under the License.
# */

from flask import jsonify
import functions_framework
import logging
import google.cloud.logging
from google.cloud import storage
from google.cloud import monitoring_v3
import time
from google.cloud import resourcemanager_v3
import traceback


def list_projects_in_folder(folder_id: str, resource_manager_client=resourcemanager_v3.ProjectsClient()):
    """Lists all projects within a given folder.

    Args:
        folder_id: The ID of the folder (e.g., "123456789012").

    Returns:
        A list of project names, or an empty list if there are no projects
        or if an error occurs.
    """
    projects = resource_manager_client.list_projects(parent=f"folders/{folder_id}")
    project_names = [project.project_id for project in projects]
    return project_names


def get_storage_total_bytes(project_name: str,
                            bucket_name: str,
                            client=monitoring_v3.MetricServiceClient(),
                            interval_mins=10,
                            ):
    """Queries Cloud Monitoring API for storage.googleapis.com/storage/total_bytes.

    Args:
        project_name: Your Google Cloud project name.
        bucket_name: The name of the GCS bucket.
        interval_minutes: The time interval for the query. Less than 10 doesn't capture a metric value for
        storage/total_bytes.

    Returns:
        The number of bytes in the bucket according to the last data point in the time series
        sampled by CLoud Monitoring.

        :param project_name: name of the project containing the bucket.
        :param bucket_name: bucket name of which the last sampled size in bytes to be returned.
        :param interval_mins: time series interval in minutes.
        :param client: monitoring_v3.MetricServiceClient().
    """

    now = time.time()
    seconds = int(now)
    nanos = int((now - seconds) * 10**9)
    interval = monitoring_v3.TimeInterval(
        {
            "end_time": {"seconds": seconds, "nanos": nanos},
            "start_time": {"seconds": (seconds - 60 * interval_mins), "nanos": nanos},
        }
    )

    # storage.googleapis.com/storage/total_bytes
    # Total size of all objects in the bucket, grouped by storage class.
    # Soft-deleted objects are not included in the total;
    # use the updated v2 metric for a breakdown of total usage including soft-deleted objects.
    # This value is measured once per day, and there might be a delay after measuring before the value
    # becomes available in Cloud Monitoring. Once available, the value is repeated at each sampling interval
    # throughout the day. Buckets with no objects in them are not tracked by this metric. For this metric,
    # the sampling period is a reporting period, not a measurement period.
    metric = "storage.googleapis.com/storage/total_bytes"

    results = client.list_time_series(
        request={
            "name": f"projects/{project_name}",
            "filter": f"""
                        metric.type = "{metric}"
                        AND resource.type = "gcs_bucket"
                        AND resource.labels.bucket_name = "{bucket_name}"
                    """,
            "interval": interval,
            "view": monitoring_v3.ListTimeSeriesRequest.TimeSeriesView.FULL,
        }
    )

    for time_series in results:  # Should be only one time series
        if len(time_series.points) > 0:  # Check for data points
            last_point = time_series.points[-1]  # Get the last point
            return last_point.value.double_value  # Return the last value

    return None  # No data points found


def map_to_list_of_key_value_maps(input_map):
    """Converts a map to a list of key-value maps. This makes it easy to parse in BigQuery

    Args:
        input_map: A dictionary (map) where keys are strings and values can be anything.

    Returns:
        A list of dictionaries, where each dictionary has "key" and "value" attributes.
        Returns an empty list if the input map is empty or None.
    """

    if not input_map:
        return []

    output_list = []
    for key, value in input_map.items():
        output_list.append({"key": key, "value": value})
    return output_list


def list_buckets_metadata(project_name: str,
                          storage_client=storage.Client(),
                          monitoring_client=monitoring_v3.MetricServiceClient()):

    buckets_metadata = []

    buckets = storage_client.list_buckets(project=project_name)

    for bucket in buckets:

        size_bytes = None
        errors = None
        try:
            size_bytes = get_storage_total_bytes(project_name, bucket.name, monitoring_client)
        except Exception as e:
            buckets_metadata[bucket.name]["size_bytes"] = None
            errors = [f"Failed to get total_bytes from monitoring API. Details: {e}"]

        buckets_metadata.append({
            "bucket_name": bucket.name,
            "project_name": project_name,
            "storage_class": bucket.storage_class,
            "labels": map_to_list_of_key_value_maps(bucket.labels) if bucket.labels else [],
            "size_bytes": size_bytes,
            "errors": errors
        })

    return buckets_metadata


def process_calls(calls: []):

    logging_client = google.cloud.logging.Client()
    storage_client = storage.Client()
    monitoring_client = monitoring_v3.MetricServiceClient()
    resource_manager_client = resourcemanager_v3.ProjectsClient()

    # Retrieves a Cloud Logging handler based on the environment
    # you're running in and integrates the handler with the
    # Python logging module. By default this captures all logs
    # at INFO level and higher
    logging_client.setup_logging()

    replies = []
    for call in calls:
        logging.info(f"Will process bq call " + str(call))

        # level: ["folder", "project"]
        level: str = call[0]

        # entity: [organization number, folder number, project name]
        entity_id: str = call[1]

        if level == "project":

            try:
                buckets_metadata = list_buckets_metadata(project_name=entity_id,
                                                         storage_client=storage_client,
                                                         monitoring_client=monitoring_client)

                replies.append({"level": "project",
                                "entity_id": entity_id,
                                "buckets_metadata": buckets_metadata,
                                "errors": []})
            except Exception as e:
                formatted_error = traceback.format_exc()
                replies.append({"level": "project",
                                "entity_id": entity_id,
                                "buckets_metadata": [],
                                "errors": [f"Error while processing project '{entity_id}': {formatted_error}"]})

        elif level == "folder":
            folder_buckets_metadata = []
            folder_errors = []

            try:
                folder_projects = list_projects_in_folder(folder_id=entity_id,
                                                          resource_manager_client=resource_manager_client)

                if folder_projects is None:
                    msg = f"No projects are listed under folder '{entity_id}'. "
                    f"Either the folder is empty or this function doesn't have the required "
                    f"permissions on that folder."

                    replies.append({"level": "folder",
                                    "entity_id": entity_id,
                                    "buckets_metadata": [],
                                    "errors": [f"{msg}"]})
                else:  # if folder projects are not None

                    for project in folder_projects:
                        try:
                            project_buckets_metadata = list_buckets_metadata(project_name=project,
                                                                             storage_client=storage_client,
                                                                             monitoring_client=monitoring_client)
                            # accumulate the project level buckets metadata to return in one reply
                            folder_buckets_metadata.extend(project_buckets_metadata)
                        except Exception as e:
                            # accumulate the project level errors to return in one reply
                            folder_errors.append(e)

                replies.append({"level": "folder",
                                "entity_id": entity_id,
                                "buckets_metadata": folder_buckets_metadata,
                                "errors": folder_errors})

            except Exception as e:
                formatted_error = traceback.format_exc()
                replies.append({"level": "folder",
                                "entity_id": entity_id,
                                "buckets_metadata": [],
                                "errors": [f"Errors while processing folder '{entity_id}': {formatted_error}"]})

        else:  # if level not in ['folder','project']
            raise Exception("'level' only supports ['folder','project']")

    return replies


@functions_framework.http
def process_request(request):

    # Instantiates a client
    logging_client = google.cloud.logging.Client()

    # Retrieves a Cloud Logging handler based on the environment
    # you're running in and integrates the handler with the
    # Python logging module. By default this captures all logs
    # at INFO level and higher
    logging_client.setup_logging()

    try:
        request_json = request.get_json()

        # the function should be implemented in a way that receives a batch of calls. Each element in the calls array
        # is 1 record-level invocation in BQ SQL
        calls = request_json['calls']

        calls_count = len(calls)
        logging.info(f"Received {calls_count} calls from BQ.")

        replies = process_calls(calls)

        return_json = jsonify({"replies": replies})
        logging.info(f"Function call ending. Replies count {len(replies)}")
        return return_json, 200

    except Exception as e:
        formatted_error = traceback.format_exc()
        error_message = f"Error while processing request: {str(formatted_error)}"
        logging.error(formatted_error)
        return jsonify({"errorMessage": error_message}), 400

