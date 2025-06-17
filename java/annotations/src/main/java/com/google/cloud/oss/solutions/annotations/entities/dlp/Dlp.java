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

package com.google.cloud.oss.solutions.annotations.entities.dlp;

/** Dlp class that contains the descriptor and field accessor table for the Dlp proto. */
public final class Dlp {
  static final com.google.protobuf.Descriptors.Descriptor
      internal_static_com_google_cloud_pso_bq_pii_classifier_entities_dlp_DataProfileAction_descriptor;
  static final com.google.protobuf.GeneratedMessage.FieldAccessorTable
      internal_static_com_google_cloud_pso_bq_pii_classifier_entities_dlp_DataProfileAction_fieldAccessorTable;
  static final com.google.protobuf.Descriptors.Descriptor
      internal_static_com_google_cloud_pso_bq_pii_classifier_entities_dlp_TableDataProfile_descriptor;
  static final com.google.protobuf.GeneratedMessage.FieldAccessorTable
      internal_static_com_google_cloud_pso_bq_pii_classifier_entities_dlp_TableDataProfile_fieldAccessorTable;
  static final com.google.protobuf.Descriptors.Descriptor
      internal_static_com_google_cloud_pso_bq_pii_classifier_entities_dlp_FileStoreDataProfile_descriptor;
  static final com.google.protobuf.GeneratedMessage.FieldAccessorTable
      internal_static_com_google_cloud_pso_bq_pii_classifier_entities_dlp_FileStoreDataProfile_fieldAccessorTable;
  static final com.google.protobuf.Descriptors.Descriptor
      internal_static_com_google_cloud_pso_bq_pii_classifier_entities_dlp_DataProfilePubSubMessage_descriptor;
  static final com.google.protobuf.GeneratedMessage.FieldAccessorTable
      internal_static_com_google_cloud_pso_bq_pii_classifier_entities_dlp_DataProfilePubSubMessage_fieldAccessorTable;
  private static final com.google.protobuf.Descriptors.FileDescriptor descriptor;

  static {
    com.google.protobuf.RuntimeVersion.validateProtobufGencodeVersion(
        com.google.protobuf.RuntimeVersion.RuntimeDomain.PUBLIC,
        /* major= */ 4,
        /* minor= */ 29,
        /* patch= */ 3,
        /* suffix= */ "",
        Dlp.class.getName());
  }

  static {
    java.lang.String[] descriptorData = {
      "\n\tdlp.proto\0223com.google.cloud.pso.bq_pii"
          + "_classifier.entities.dlp\"\212\001\n\021DataProfile"
          + "Action\"u\n\tEventType\022\032\n\026EVENT_TYPE_UNSPEC"
          + "IFIED\020\000\022\017\n\013NEW_PROFILE\020\001\022\023\n\017CHANGED_PROF"
          + "ILE\020\002\022\023\n\017SCORE_INCREASED\020\003\022\021\n\rERROR_CHAN"
          + "GED\020\004\"7\n\020TableDataProfile\022\014\n\004name\030\001 \001(\t\022"
          + "\025\n\rfull_resource\030\003 \001(\t\"=\n\024FileStoreDataP"
          + "rofile\022\014\n\004name\030\001 \001(\t\022\027\n\017file_store_path\030"
          + "\006 \001(\t\"\272\002\n\030DataProfilePubSubMessage\022V\n\007pr"
          + "ofile\030\001 \001(\0132E.com.google.cloud.pso.bq_pi"
          + "i_classifier.entities.dlp.TableDataProfi"
          + "le\022_\n\005event\030\002 \001(\0162P.com.google.cloud.pso"
          + ".bq_pii_classifier.entities.dlp.DataProf"
          + "ileAction.EventType\022e\n\022file_store_profil"
          + "e\030\003 \001(\0132I.com.google.cloud.pso.bq_pii_cl"
          + "assifier.entities.dlp.FileStoreDataProfi"
          + "leB7\n3com.google.cloud.pso.bq_pii_classi"
          + "fier.entities.dlpP\001b\006proto3"
    };
    descriptor =
        com.google.protobuf.Descriptors.FileDescriptor.internalBuildGeneratedFileFrom(
            descriptorData, new com.google.protobuf.Descriptors.FileDescriptor[] {});
    internal_static_com_google_cloud_pso_bq_pii_classifier_entities_dlp_DataProfileAction_descriptor =
        getDescriptor().getMessageTypes().get(0);
    internal_static_com_google_cloud_pso_bq_pii_classifier_entities_dlp_DataProfileAction_fieldAccessorTable =
        new com.google.protobuf.GeneratedMessage.FieldAccessorTable(
            internal_static_com_google_cloud_pso_bq_pii_classifier_entities_dlp_DataProfileAction_descriptor,
            new java.lang.String[] {});
    internal_static_com_google_cloud_pso_bq_pii_classifier_entities_dlp_TableDataProfile_descriptor =
        getDescriptor().getMessageTypes().get(1);
    internal_static_com_google_cloud_pso_bq_pii_classifier_entities_dlp_TableDataProfile_fieldAccessorTable =
        new com.google.protobuf.GeneratedMessage.FieldAccessorTable(
            internal_static_com_google_cloud_pso_bq_pii_classifier_entities_dlp_TableDataProfile_descriptor,
            new java.lang.String[] {
              "Name", "FullResource",
            });
    internal_static_com_google_cloud_pso_bq_pii_classifier_entities_dlp_FileStoreDataProfile_descriptor =
        getDescriptor().getMessageTypes().get(2);
    internal_static_com_google_cloud_pso_bq_pii_classifier_entities_dlp_FileStoreDataProfile_fieldAccessorTable =
        new com.google.protobuf.GeneratedMessage.FieldAccessorTable(
            internal_static_com_google_cloud_pso_bq_pii_classifier_entities_dlp_FileStoreDataProfile_descriptor,
            new java.lang.String[] {
              "Name", "FileStorePath",
            });
    internal_static_com_google_cloud_pso_bq_pii_classifier_entities_dlp_DataProfilePubSubMessage_descriptor =
        getDescriptor().getMessageTypes().get(3);
    internal_static_com_google_cloud_pso_bq_pii_classifier_entities_dlp_DataProfilePubSubMessage_fieldAccessorTable =
        new com.google.protobuf.GeneratedMessage.FieldAccessorTable(
            internal_static_com_google_cloud_pso_bq_pii_classifier_entities_dlp_DataProfilePubSubMessage_descriptor,
            new java.lang.String[] {
              "Profile", "Event", "FileStoreProfile",
            });
    descriptor.resolveAllFeaturesImmutable();
  }

  private Dlp() {}

  public static void registerAllExtensions(com.google.protobuf.ExtensionRegistryLite registry) {}

  public static void registerAllExtensions(com.google.protobuf.ExtensionRegistry registry) {
    registerAllExtensions((com.google.protobuf.ExtensionRegistryLite) registry);
  }

  public static com.google.protobuf.Descriptors.FileDescriptor getDescriptor() {
    return descriptor;
  }

  // @@protoc_insertion_point(outer_class_scope)
}
