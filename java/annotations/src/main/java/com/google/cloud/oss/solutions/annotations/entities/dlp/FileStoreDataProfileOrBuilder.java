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

/** Interface for FileStoreDataProfile or Builder. */
public interface FileStoreDataProfileOrBuilder
    extends
    // @@protoc_insertion_point(interface_extends:com.google.internal.spma.annotations.entities.dlp.FileStoreDataProfile)
    com.google.protobuf.MessageOrBuilder {

  /**
   *
   *
   * <pre>
   * The name of the profile.
   * </pre>
   *
   * <code>string name = 1;</code>
   *
   * @return The name.
   */
  java.lang.String getName();

  /**
   *
   *
   * <pre>
   * The name of the profile.
   * </pre>
   *
   * <code>string name = 1;</code>
   *
   * @return The bytes for name.
   */
  com.google.protobuf.ByteString getNameBytes();

  /**
   *
   *
   * <pre>
   * The path of the file store.
   * </pre>
   *
   * <code>string file_store_path = 6;</code>
   *
   * @return The fileStorePath.
   */
  java.lang.String getFileStorePath();

  /**
   *
   *
   * <pre>
   * The path of the file store.
   * </pre>
   *
   * <code>string file_store_path = 6;</code>
   *
   * @return The bytes for fileStorePath.
   */
  com.google.protobuf.ByteString getFileStorePathBytes();
}
