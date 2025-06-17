/*
 *
 *  Copyright 2025 Google LLC
 *
 *  Licensed under the Apache License, Version 2.0 (the "License");
 *  you may not use this file except in compliance with the License.
 *  You may obtain a copy of the License at
 *
 *       https://www.apache.org/licenses/LICENSE-2.0
 *
 *  Unless required by applicable law or agreed to in writing, software
 *  distributed under the License is distributed on an "AS IS" BASIS,
 *  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or
 *  implied.
 *  See the License for the specific language governing permissions and
 *  limitations under the License.
 *
 */

package com.google.cloud.oss.solutions.annotations.services.findings;

import com.google.cloud.dlp.v2.DlpServiceClient;
import com.google.cloud.oss.solutions.annotations.entities.DlpFieldFindings;
import com.google.cloud.oss.solutions.annotations.entities.DlpOtherInfoTypeMatch;
import com.google.cloud.oss.solutions.annotations.entities.GcsDlpProfileSummary;
import com.google.cloud.oss.solutions.annotations.entities.NonRetryableApplicationException;
import com.google.cloud.oss.solutions.annotations.helpers.Utils;
import com.google.privacy.dlp.v2.ColumnDataProfile;
import com.google.privacy.dlp.v2.FileStoreDataProfile;
import com.google.privacy.dlp.v2.ListColumnDataProfilesRequest;
import java.io.IOException;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

/** Implementation of {@link DlpFindingsReader} to read DLP findings from GCP. */
public class DlpFindingsReaderImpl implements DlpFindingsReader {

  @Override
  public GcsDlpProfileSummary getGcsDlpProfileSummary(String fileStoreDataProfileName)
      throws IOException, NonRetryableApplicationException {

    try (DlpServiceClient dlpServiceClient = DlpServiceClient.create()) {

      FileStoreDataProfile dataProfile =
          dlpServiceClient.getFileStoreDataProfile(fileStoreDataProfileName);

      if (dataProfile == null) {
        throw new NonRetryableApplicationException(
            String.format("No file store data profile found for '%s'", fileStoreDataProfileName));
      }

      return GcsDlpProfileSummary.fromDlpFileStoreDataProfile(dataProfile);
    }
  }

  @Override
  public Map<String, DlpFieldFindings> getBigQueryDlpProfileSummary(String tableProfileName)
      throws IOException {

    Map<String, DlpFieldFindings> fieldsFindings = new HashMap<>();

    try (DlpServiceClient dlpServiceClient = DlpServiceClient.create()) {

      String dlpParent = Utils.extractDlpParentFromProfile(tableProfileName);

      ListColumnDataProfilesRequest request =
          ListColumnDataProfilesRequest.newBuilder()
              .setParent(dlpParent)
              .setFilter(String.format("table_data_profile_name = %s", tableProfileName))
              .build();

      DlpServiceClient.ListColumnDataProfilesPagedResponse response =
          dlpServiceClient.listColumnDataProfiles(request);

      Iterable<ColumnDataProfile> columnProfiles = response.iterateAll();

      for (ColumnDataProfile p : columnProfiles) {
        String infoType = p.getColumnInfoType().getInfoType().getName();
        List<DlpOtherInfoTypeMatch> otherInfoTypes =
            p.getOtherMatchesList().stream()
                .map(
                    x ->
                        new DlpOtherInfoTypeMatch(
                            x.getInfoType().getName(), x.getEstimatedPrevalence()))
                .toList();

        fieldsFindings.put(p.getColumn(), new DlpFieldFindings(infoType, otherInfoTypes));
      }
    }

    return fieldsFindings;
  }
}
