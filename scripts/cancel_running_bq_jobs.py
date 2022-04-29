# /usr/bin/python

# Usage:
# python -m venv /tmp/venv/bq-pii-classifier
# source /tmp/venv/bq-pii-classifier/bin/activate
# pip install google-cloud-bigquery
# python scripts/cancel_running_bq_jobs.py

# This is a dev utility script to cancel running and pending BQ jobs

from google.cloud import bigquery

import datetime

# Construct a BigQuery client object.
client = bigquery.Client()

# Use all_users to include jobs run by all users in the project.
print("Running Jobs:")
for job in client.list_jobs(max_results=1000, all_users=True, state_filter="running"):
    print("Will cancel job_id {} | user: {} | state : {}".format(job.job_id, job.user_email, job.state))
    client.cancel_job(job.job_id)

print("Pending Jobs:")
for job in client.list_jobs(max_results=1000, all_users=True, state_filter="pending"):
    print("Will cancel job_id {} | user: {} | state : {}".format(job.job_id, job.user_email, job.state))
    client.cancel_job(job.job_id)
