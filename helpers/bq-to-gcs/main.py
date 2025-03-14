# main.py
import os
import json
from google.cloud import bigquery
from google.cloud import storage
import vertexai
from vertexai.language_models import TextGenerationModel
from vertexai.generative_models import GenerativeModel
import uuid

PROJECT_ID = ""
DATASET_ID = ""
TABLE_ID = ""
BUCKET_NAME = ""
LOCATION = ""


if __name__ == "__main__":
    try:

        # Initialize clients
        bq_client = bigquery.Client(project=PROJECT_ID)
        storage_client = storage.Client(project=PROJECT_ID)
        vertexai.init(project=PROJECT_ID, location=LOCATION)

        model = GenerativeModel(model_name="gemini-2.0-flash")

        # BigQuery query
        query = f"""
            SELECT *
            FROM `{PROJECT_ID}.{DATASET_ID}.{TABLE_ID}` LIMIT 50
        """
        query_job = bq_client.query(query)
        results = query_job.result()

        # Process each row
        for row in results:
            row_json = json.dumps(dict(row.items()), default=str)  # Convert row to JSON

            prompt = f"""
            Generate a PNG image that includes a table with the customer details listed in this json:

            {row_json}
            """
            # Call LLM
            response = model.generate_content(prompt)
            document = response.text

            # Upload to Cloud Storage
            blob_name = f"images/document_{uuid.uuid4()}.png"  # Unique filename
            bucket = storage_client.bucket(BUCKET_NAME)
            blob = bucket.blob(blob_name)
            blob.upload_from_string(document)

            print(f"Document uploaded: gs://{BUCKET_NAME}/unstructured-text/{blob_name}")

    except Exception as e:
        print(f"Error: {e}")