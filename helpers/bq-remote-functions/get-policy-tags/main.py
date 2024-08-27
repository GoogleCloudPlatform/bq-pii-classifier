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
import os
from flask import jsonify
from google.cloud import logging
import functions_framework
from google.cloud import bigquery
from google.cloud.datacatalog import PolicyTagManagerClient
from google.cloud import datacatalog_v1
from google.cloud import datastore
import datetime
import pytz  # Import the pytz library
import logging
import google.cloud.logging


class DatastoreCache:
    def __init__(self, kind='PolicyTagsCache', database_name='(default)'):
        self.datastore_client = datastore.Client(database=database_name)
        self.kind = kind

    def get(self, key):
        """Retrieves a cached value from Datastore."""
        key = self.datastore_client.key(self.kind, key)
        entity = self.datastore_client.get(key)

        if entity and 'value' in entity and 'expiration' in entity:
            # Make now timezone-aware (assuming UTC)
            now_aware = datetime.datetime.now(pytz.utc)

            if entity['expiration'] > now_aware:
                return entity['value']
            else:
                # Expired entry, delete it
                self.datastore_client.delete(key)

        return None  # Cache miss or expired entry

    def add(self, key, value, expiration_seconds=3600):
        """Adds or updates a cached value in Datastore with an expiration time."""
        key = self.datastore_client.key(self.kind, key)
        entity = datastore.Entity(key=key)

        # Make expiration timezone-aware (assuming UTC)
        expiration = datetime.datetime.now(pytz.utc) + datetime.timedelta(seconds=expiration_seconds)

        entity.update({
            'value': value,
            'expiration': expiration
        })
        self.datastore_client.put(entity)


def get_column_policy_tags(project_id, dataset_id, table_id):
    """Fetches policy tags associated with BigQuery table columns."""
    bq_client = bigquery.Client(project=project_id)
    table_ref = bq_client.dataset(dataset_id).table(table_id)

    try:
        table = bq_client.get_table(table_ref)
    except Exception as e:
        return None, str(e)

    policy_tags = {}
    for field in table.schema:
        if field.policy_tags:
            for tag in field.policy_tags.names:
                policy_tags[field.name] = tag
    return policy_tags, None


def get_policy_tag_display_names(policy_tags, cache):
    """Looks up the display names of policy tags using Data Catalog."""
    datacatalog_client = datacatalog_v1.PolicyTagManagerClient()
    tag_names = list(policy_tags.values())

    display_names = {}
    for name in tag_names:
        try:
            # 1) get from datastore
            cached_policy_tag_display_name = cache.get(name)
            if cached_policy_tag_display_name:
                display_names[name] = cached_policy_tag_display_name
            else:
                # API call
                tag = datacatalog_client.get_policy_tag(name=name)
                display_names[name] = tag.display_name
                cache.add(name, tag.display_name)
        except Exception as e:
            display_names[name] = f'Failed to retrieve policy tag display name for {name}. Exception: {e}'

    return display_names


def combine_policy_tags(policy_tags_ids, policy_tags_names):
    """Combines policy tag IDs and names into a list of dictionaries.

    Args:
        policy_tags_ids: A dictionary mapping column names to policy tag IDs.
        policy_tags_names: A dictionary mapping policy tag IDs to their names.

    Returns:
        A list of dictionaries, each containing a column name, policy tag ID, and policy tag name.
    """
    result = []
    for column, policy_tag_id in policy_tags_ids.items():
        policy_tag_name = policy_tags_names.get(policy_tag_id, "Not Found")
        result.append({
            "column": column,
            "policy_tag_id": policy_tag_id,
            "policy_tag_name": policy_tag_name
        })
    return result


@functions_framework.http
def process_request(request):

    datastore_cache_db_name = os.environ.get("DATASTORE_CACHE_DB_NAME")

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

        # create a cache for policy tags display names
        cache = DatastoreCache(database_name=datastore_cache_db_name)

        replies = []
        for call in calls:
            logging.info(f"Will process bq call " + str(call))

            table_spec = call[0].strip('`')

            table_spec_splits = table_spec.split(".")
            table_project = table_spec_splits[0]
            table_dataset = table_spec_splits[1]
            table_name = table_spec_splits[2]

            policy_tags_ids, error = get_column_policy_tags(table_project, table_dataset, table_name)
            if not error:
                policy_tags_names = get_policy_tag_display_names(policy_tags_ids, cache)
                final_result_list = combine_policy_tags(policy_tags_ids, policy_tags_names)
                call_result = {"columns_and_policy_tags": final_result_list, "error": None}
                replies.append(call_result)
            else:
                call_result = {"columns_and_policy_tags": [], "error": error}
                replies.append(call_result)

        return_json = jsonify({"replies": replies})
        logging.info(f"Function call ending. Replies count {len(replies)}")
        return return_json, 200

    except Exception as e:
        logging.error(f"Error while processing request {str(e)}")
        return jsonify({"errorMessage": str(e)}), 400
