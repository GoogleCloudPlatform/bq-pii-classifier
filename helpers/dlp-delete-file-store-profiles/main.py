from google.cloud import dlp_v2
import argparse

def delete_all_data_profiles(parent, *regions):

    client = dlp_v2.DlpServiceClient()

    for region in regions:
        regional_parent = f"{parent}/locations/{region}"

        try:
            # List data profiles in the region
            request = dlp_v2.ListFileStoreDataProfilesRequest(
                parent=regional_parent,
            )
            profiles = client.list_file_store_data_profiles(request=request)

            for profile in profiles:
                print(f"Deleting profile {profile.name} ..")
                client.delete_file_store_data_profile(request=dlp_v2.DeleteFileStoreDataProfileRequest(
                    name=profile.name,
                ))

        except Exception as e:
            print(f"Error listing file store data profiles in {region}: {e}")


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Delete file store data profiles from DLP by region.")
    parser.add_argument("dlp_parent", help="organizations/<number> or projects/<number>")
    parser.add_argument("regions", nargs="+", help="The DLP regions where file store profiles are to be deleted")
    args = parser.parse_args()
    delete_all_data_profiles(args.dlp_parent, *args.regions)