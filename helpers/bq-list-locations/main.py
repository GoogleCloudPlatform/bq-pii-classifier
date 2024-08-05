from google.cloud import bigquery


def get_dataset_locations(project_id):
    """Fetches all unique BigQuery dataset locations for a project."""

    client = bigquery.Client(project=project_id)

    bq_locations = set()

    for dataset_list_item in client.list_datasets():
        dataset = client.get_dataset(dataset_list_item.reference)  # Get full dataset object
        bq_locations.add(dataset.location)  # Access the location from the full object

    return bq_locations

# Example usage
project_id = "example-project"  # Replace with your actual project ID
locations = get_dataset_locations(project_id)
print("Dataset locations:", locations)