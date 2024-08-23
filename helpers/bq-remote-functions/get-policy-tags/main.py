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
from google.cloud import logging
import functions_framework
from google.cloud import bigquery
from google.cloud.datacatalog import PolicyTagManagerClient
from google.cloud import datacatalog_v1


def get_column_policy_tags(project_id, dataset_id, table_id):
    """Fetches policy tags associated with BigQuery table columns."""
    bq_client = bigquery.Client(project=project_id)
    table_ref = bq_client.dataset(dataset_id).table(table_id)
    table = bq_client.get_table(table_ref)

    policy_tags = {}
    for field in table.schema:
        if field.policy_tags:
            for tag in field.policy_tags.names:
                policy_tags[field.name] = tag
    return policy_tags


def get_policy_tag_display_names(policy_tags):
    """Looks up the display names of policy tags using Data Catalog."""
    datacatalog_client = datacatalog_v1.PolicyTagManagerClient()
    tag_names = list(policy_tags.values())

    display_names = {}
    for name in tag_names:
        try:
            tag = datacatalog_client.get_policy_tag(name=name)
            display_names[name] = tag.display_name
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
    try:

        logger = logging.Client().logger("bq-remote-func-get-policy-tags")

        request_json = request.get_json()

        # the function should be implemented in a way that receives a batch of calls. Each element in the calls array
        # is 1 record-level invocation in BQ SQL
        calls = request_json['calls']

        calls_count = len(calls)
        logger.log_text(
            f"Received {calls_count} calls from BQ. Calls: " + str(calls),
            severity="INFO"
        )

        replies = []
        for call in calls:
            logger.log_text(
                f"Will process bq call " + str(call),
                severity="INFO"
            )
            table_spec = call[0].strip('`')

            table_spec_splits = table_spec.split(".")
            table_project = table_spec_splits[0]
            table_dataset = table_spec_splits[1]
            table_name = table_spec_splits[2]

            policy_tags_ids = get_column_policy_tags(table_project, table_dataset, table_name)
            policy_tags_names = get_policy_tag_display_names(policy_tags_ids)

            final_result_list = combine_policy_tags(policy_tags_ids, policy_tags_names)

            call_result = {"columns_and_policy_tags": final_result_list}
            replies.append(call_result)

        return_json = jsonify({"replies": replies})
        logger.log_text(
            f"Function call ending. Replies {replies}",
            severity="INFO"
        )
        return return_json, 200

    except Exception as e:
        logger.log_text(
            str(e),
            severity="ERROR"
        )
        return jsonify({"errorMessage": str(e)}), 400
