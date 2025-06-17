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

/**
 * Protobuf type {@code com.google.internal.spma.annotations.entities.dlp.DataProfilePubSubMessage}
 */
public interface DataProfilePubSubMessageOrBuilder
    extends
    // @@protoc_insertion_point(interface_extends:com.google.internal.spma.annotations.entities.dlp.DataProfilePubSubMessage)
    com.google.protobuf.MessageOrBuilder {

  /**
   *
   *
   * <pre>
   * If `DetailLevel` is `TABLE_PROFILE` this will be fully populated.
   * Otherwise, if `DetailLevel` is `RESOURCE_NAME`, then only `name` and
   * `full_resource` will be populated.
   * </pre>
   *
   * <code>.com.google.internal.spma.annotations.entities.dlp.TableDataProfile profile = 1;</code>
   *
   * @return Whether the profile field is set.
   */
  boolean hasProfile();

  /**
   *
   *
   * <pre>
   * If `DetailLevel` is `TABLE_PROFILE` this will be fully populated.
   * Otherwise, if `DetailLevel` is `RESOURCE_NAME`, then only `name` and
   * `full_resource` will be populated.
   * </pre>
   *
   * <code>.com.google.internal.spma.annotations.entities.dlp.TableDataProfile profile = 1;</code>
   *
   * @return The profile.
   */
  TableDataProfile getProfile();

  /**
   *
   *
   * <pre>
   * If `DetailLevel` is `TABLE_PROFILE` this will be fully populated.
   * Otherwise, if `DetailLevel` is `RESOURCE_NAME`, then only `name` and
   * `full_resource` will be populated.
   * </pre>
   *
   * <code>.com.google.internal.spma.annotations.entities.dlp.TableDataProfile profile = 1;</code>
   */
  TableDataProfileOrBuilder getProfileOrBuilder();

  /**
   *
   *
   * <pre>
   * The event that caused the Pub/Sub message to be sent.
   * </pre>
   *
   * <code>
   * .com.google.internal.spma.annotations.entities.dlp.DataProfileAction.EventType event = 2;
   * </code>
   *
   * @return The enum numeric value on the wire for event.
   */
  int getEventValue();

  /**
   *
   *
   * <pre>
   * The event that caused the Pub/Sub message to be sent.
   * </pre>
   *
   * <code>
   * .com.google.internal.spma.annotations.entities.dlp.DataProfileAction.EventType event = 2;
   * </code>
   *
   * @return The event.
   */
  DataProfileAction.EventType getEvent();

  /**
   *
   *
   * <pre>
   * If `DetailLevel` is `FILE_STORE_PROFILE` this will be fully populated.
   * Otherwise, if `DetailLevel` is `RESOURCE_NAME`, then only `name` and
   * `file_store_path` will be populated.
   * </pre>
   *
   * <code>
   * .com.google.internal.spma.annotations.entities.dlp.FileStoreDataProfile file_store_profile = 3;
   * </code>
   *
   * @return Whether the fileStoreProfile field is set.
   */
  boolean hasFileStoreProfile();

  /**
   *
   *
   * <pre>
   * If `DetailLevel` is `FILE_STORE_PROFILE` this will be fully populated.
   * Otherwise, if `DetailLevel` is `RESOURCE_NAME`, then only `name` and
   * `file_store_path` will be populated.
   * </pre>
   *
   * <code>
   * .com.google.internal.spma.annotations.entities.dlp.FileStoreDataProfile file_store_profile = 3;
   * </code>
   *
   * @return The fileStoreProfile.
   */
  FileStoreDataProfile getFileStoreProfile();

  /**
   *
   *
   * <pre>
   * If `DetailLevel` is `FILE_STORE_PROFILE` this will be fully populated.
   * Otherwise, if `DetailLevel` is `RESOURCE_NAME`, then only `name` and
   * `file_store_path` will be populated.
   * </pre>
   *
   * <code>
   * .com.google.internal.spma.annotations.entities.dlp.FileStoreDataProfile file_store_profile = 3;
   * </code>
   */
  FileStoreDataProfileOrBuilder getFileStoreProfileOrBuilder();
}
