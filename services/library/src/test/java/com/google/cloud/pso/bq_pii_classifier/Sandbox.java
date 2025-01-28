package com.google.cloud.pso.bq_pii_classifier;

import com.google.cloud.dlp.v2.DlpServiceClient;
import com.google.privacy.dlp.v2.FileStoreDataProfile;
import org.junit.Test;

import java.io.IOException;
import java.util.Set;
import java.util.stream.Collectors;

public class Sandbox {

    @Test
    public void test() throws IOException {

        String parent = "organizations/910444929556/locations/europe";

        try (DlpServiceClient dlpServiceClient = DlpServiceClient.create()) {



            DlpServiceClient.ListFileStoreDataProfilesPagedResponse pagedResponseList = dlpServiceClient.listFileStoreDataProfiles(parent);
            for(FileStoreDataProfile profile: pagedResponseList.iterateAll()){
                System.out.println("START ------- "+ profile.getName() +" ------------");
                String profileName = profile.getName();
                String bucketProject = profile.getProjectId();
                String bucketPath = profile.getFileStorePath();
                Set<String> infoTypes = profile.getFileStoreInfoTypeSummariesList().stream().map(x->x.getInfoType().getName()).collect(Collectors.toSet());
                System.out.println(profileName);
                System.out.println(bucketProject);
                System.out.println(bucketPath);
                System.out.println(infoTypes);
                System.out.println("END -------------------");
            }
        }
    }
}
