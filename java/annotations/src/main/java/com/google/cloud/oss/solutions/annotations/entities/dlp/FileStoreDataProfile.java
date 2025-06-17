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
 *
 *
 * <pre>
 * The profile for a scanned FileStore.
 * </pre>
 *
 * Protobuf type {@code com.google.internal.spma.annotations.entities.dlp.FileStoreDataProfile}
 */
public final class FileStoreDataProfile extends com.google.protobuf.GeneratedMessage
    implements
    // @@protoc_insertion_point(message_implements:com.google.internal.spma.annotations.entities.dlp.FileStoreDataProfile)
    FileStoreDataProfileOrBuilder {
  public static final int NAME_FIELD_NUMBER = 1;
  public static final int FILE_STORE_PATH_FIELD_NUMBER = 6;
  private static final long serialVersionUID = 0L;
  // @@protoc_insertion_point(class_scope:com.google.internal.spma.annotations.entities.dlp.FileStoreDataProfile)
  private static final FileStoreDataProfile DEFAULT_INSTANCE;
  private static final com.google.protobuf.Parser<FileStoreDataProfile> PARSER =
      new com.google.protobuf.AbstractParser<FileStoreDataProfile>() {
        @java.lang.Override
        public FileStoreDataProfile parsePartialFrom(
            com.google.protobuf.CodedInputStream input,
            com.google.protobuf.ExtensionRegistryLite extensionRegistry)
            throws com.google.protobuf.InvalidProtocolBufferException {
          Builder builder = newBuilder();
          try {
            builder.mergeFrom(input, extensionRegistry);
          } catch (com.google.protobuf.InvalidProtocolBufferException e) {
            throw e.setUnfinishedMessage(builder.buildPartial());
          } catch (com.google.protobuf.UninitializedMessageException e) {
            throw e.asInvalidProtocolBufferException().setUnfinishedMessage(builder.buildPartial());
          } catch (java.io.IOException e) {
            throw new com.google.protobuf.InvalidProtocolBufferException(e)
                .setUnfinishedMessage(builder.buildPartial());
          }
          return builder.buildPartial();
        }
      };

  static {
    com.google.protobuf.RuntimeVersion.validateProtobufGencodeVersion(
        com.google.protobuf.RuntimeVersion.RuntimeDomain.PUBLIC,
        /* major= */ 4,
        /* minor= */ 29,
        /* patch= */ 3,
        /* suffix= */ "",
        FileStoreDataProfile.class.getName());
  }

  static {
    DEFAULT_INSTANCE = new FileStoreDataProfile();
  }

  @SuppressWarnings("serial")
  private volatile java.lang.Object name_ = "";

  @SuppressWarnings("serial")
  private volatile java.lang.Object fileStorePath_ = "";

  private byte memoizedIsInitialized = -1;

  // Use FileStoreDataProfile.newBuilder() to construct.
  private FileStoreDataProfile(com.google.protobuf.GeneratedMessage.Builder<?> builder) {
    super(builder);
  }

  private FileStoreDataProfile() {
    name_ = "";
    fileStorePath_ = "";
  }

  public static com.google.protobuf.Descriptors.Descriptor getDescriptor() {
    return Dlp
        .internal_static_com_google_cloud_pso_bq_pii_classifier_entities_dlp_FileStoreDataProfile_descriptor;
  }

  public static FileStoreDataProfile parseFrom(java.nio.ByteBuffer data)
      throws com.google.protobuf.InvalidProtocolBufferException {
    return PARSER.parseFrom(data);
  }

  public static FileStoreDataProfile parseFrom(
      java.nio.ByteBuffer data, com.google.protobuf.ExtensionRegistryLite extensionRegistry)
      throws com.google.protobuf.InvalidProtocolBufferException {
    return PARSER.parseFrom(data, extensionRegistry);
  }

  public static FileStoreDataProfile parseFrom(com.google.protobuf.ByteString data)
      throws com.google.protobuf.InvalidProtocolBufferException {
    return PARSER.parseFrom(data);
  }

  public static FileStoreDataProfile parseFrom(
      com.google.protobuf.ByteString data,
      com.google.protobuf.ExtensionRegistryLite extensionRegistry)
      throws com.google.protobuf.InvalidProtocolBufferException {
    return PARSER.parseFrom(data, extensionRegistry);
  }

  public static FileStoreDataProfile parseFrom(byte[] data)
      throws com.google.protobuf.InvalidProtocolBufferException {
    return PARSER.parseFrom(data);
  }

  public static FileStoreDataProfile parseFrom(
      byte[] data, com.google.protobuf.ExtensionRegistryLite extensionRegistry)
      throws com.google.protobuf.InvalidProtocolBufferException {
    return PARSER.parseFrom(data, extensionRegistry);
  }

  public static FileStoreDataProfile parseFrom(java.io.InputStream input)
      throws java.io.IOException {
    return com.google.protobuf.GeneratedMessage.parseWithIOException(PARSER, input);
  }

  public static FileStoreDataProfile parseFrom(
      java.io.InputStream input, com.google.protobuf.ExtensionRegistryLite extensionRegistry)
      throws java.io.IOException {
    return com.google.protobuf.GeneratedMessage.parseWithIOException(
        PARSER, input, extensionRegistry);
  }

  public static FileStoreDataProfile parseDelimitedFrom(java.io.InputStream input)
      throws java.io.IOException {
    return com.google.protobuf.GeneratedMessage.parseDelimitedWithIOException(PARSER, input);
  }

  public static FileStoreDataProfile parseDelimitedFrom(
      java.io.InputStream input, com.google.protobuf.ExtensionRegistryLite extensionRegistry)
      throws java.io.IOException {
    return com.google.protobuf.GeneratedMessage.parseDelimitedWithIOException(
        PARSER, input, extensionRegistry);
  }

  public static FileStoreDataProfile parseFrom(com.google.protobuf.CodedInputStream input)
      throws java.io.IOException {
    return com.google.protobuf.GeneratedMessage.parseWithIOException(PARSER, input);
  }

  public static FileStoreDataProfile parseFrom(
      com.google.protobuf.CodedInputStream input,
      com.google.protobuf.ExtensionRegistryLite extensionRegistry)
      throws java.io.IOException {
    return com.google.protobuf.GeneratedMessage.parseWithIOException(
        PARSER, input, extensionRegistry);
  }

  public static Builder newBuilder() {
    return DEFAULT_INSTANCE.toBuilder();
  }

  public static Builder newBuilder(FileStoreDataProfile prototype) {
    return DEFAULT_INSTANCE.toBuilder().mergeFrom(prototype);
  }

  public static FileStoreDataProfile getDefaultInstance() {
    return DEFAULT_INSTANCE;
  }

  public static com.google.protobuf.Parser<FileStoreDataProfile> parser() {
    return PARSER;
  }

  @java.lang.Override
  protected com.google.protobuf.GeneratedMessage.FieldAccessorTable
      internalGetFieldAccessorTable() {
    return Dlp
        .internal_static_com_google_cloud_pso_bq_pii_classifier_entities_dlp_FileStoreDataProfile_fieldAccessorTable
        .ensureFieldAccessorsInitialized(
            FileStoreDataProfile.class, FileStoreDataProfile.Builder.class);
  }

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
  @java.lang.Override
  public java.lang.String getName() {
    java.lang.Object ref = name_;
    if (ref instanceof java.lang.String) {
      return (java.lang.String) ref;
    } else {
      com.google.protobuf.ByteString bs = (com.google.protobuf.ByteString) ref;
      java.lang.String s = bs.toStringUtf8();
      name_ = s;
      return s;
    }
  }

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
  @java.lang.Override
  public com.google.protobuf.ByteString getNameBytes() {
    java.lang.Object ref = name_;
    if (ref instanceof java.lang.String) {
      com.google.protobuf.ByteString b =
          com.google.protobuf.ByteString.copyFromUtf8((java.lang.String) ref);
      name_ = b;
      return b;
    } else {
      return (com.google.protobuf.ByteString) ref;
    }
  }

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
  @java.lang.Override
  public java.lang.String getFileStorePath() {
    java.lang.Object ref = fileStorePath_;
    if (ref instanceof java.lang.String) {
      return (java.lang.String) ref;
    } else {
      com.google.protobuf.ByteString bs = (com.google.protobuf.ByteString) ref;
      java.lang.String s = bs.toStringUtf8();
      fileStorePath_ = s;
      return s;
    }
  }

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
  @java.lang.Override
  public com.google.protobuf.ByteString getFileStorePathBytes() {
    java.lang.Object ref = fileStorePath_;
    if (ref instanceof java.lang.String) {
      com.google.protobuf.ByteString b =
          com.google.protobuf.ByteString.copyFromUtf8((java.lang.String) ref);
      fileStorePath_ = b;
      return b;
    } else {
      return (com.google.protobuf.ByteString) ref;
    }
  }

  @java.lang.Override
  public boolean isInitialized() {
    byte isInitialized = memoizedIsInitialized;
    if (isInitialized == 1) {
      return true;
    }
    if (isInitialized == 0) {
      return false;
    }

    memoizedIsInitialized = 1;
    return true;
  }

  @java.lang.Override
  public void writeTo(com.google.protobuf.CodedOutputStream output) throws java.io.IOException {
    if (!com.google.protobuf.GeneratedMessage.isStringEmpty(name_)) {
      com.google.protobuf.GeneratedMessage.writeString(output, 1, name_);
    }
    if (!com.google.protobuf.GeneratedMessage.isStringEmpty(fileStorePath_)) {
      com.google.protobuf.GeneratedMessage.writeString(output, 6, fileStorePath_);
    }
    getUnknownFields().writeTo(output);
  }

  @java.lang.Override
  public int getSerializedSize() {
    int size = memoizedSize;
    if (size != -1) {
      return size;
    }

    size = 0;
    if (!com.google.protobuf.GeneratedMessage.isStringEmpty(name_)) {
      size += com.google.protobuf.GeneratedMessage.computeStringSize(1, name_);
    }
    if (!com.google.protobuf.GeneratedMessage.isStringEmpty(fileStorePath_)) {
      size += com.google.protobuf.GeneratedMessage.computeStringSize(6, fileStorePath_);
    }
    size += getUnknownFields().getSerializedSize();
    memoizedSize = size;
    return size;
  }

  @java.lang.Override
  public boolean equals(final java.lang.Object obj) {
    if (obj == this) {
      return true;
    }
    if (!(obj instanceof FileStoreDataProfile other)) {
      return super.equals(obj);
    }

    if (!getName().equals(other.getName())) {
      return false;
    }
    if (!getFileStorePath().equals(other.getFileStorePath())) {
      return false;
    }
    return getUnknownFields().equals(other.getUnknownFields());
  }

  @java.lang.Override
  public int hashCode() {
    if (memoizedHashCode != 0) {
      return memoizedHashCode;
    }
    int hash = 41;
    hash = (19 * hash) + getDescriptor().hashCode();
    hash = (37 * hash) + NAME_FIELD_NUMBER;
    hash = (53 * hash) + getName().hashCode();
    hash = (37 * hash) + FILE_STORE_PATH_FIELD_NUMBER;
    hash = (53 * hash) + getFileStorePath().hashCode();
    hash = (29 * hash) + getUnknownFields().hashCode();
    memoizedHashCode = hash;
    return hash;
  }

  @java.lang.Override
  public Builder newBuilderForType() {
    return newBuilder();
  }

  @java.lang.Override
  public Builder toBuilder() {
    return this == DEFAULT_INSTANCE ? new Builder() : new Builder().mergeFrom(this);
  }

  @java.lang.Override
  protected Builder newBuilderForType(com.google.protobuf.GeneratedMessage.BuilderParent parent) {
    Builder builder = new Builder(parent);
    return builder;
  }

  @java.lang.Override
  public com.google.protobuf.Parser<FileStoreDataProfile> getParserForType() {
    return PARSER;
  }

  @java.lang.Override
  public FileStoreDataProfile getDefaultInstanceForType() {
    return DEFAULT_INSTANCE;
  }

  /**
   *
   *
   * <pre>
   * The profile for a scanned FileStore.
   * </pre>
   *
   * Protobuf type {@code com.google.internal.spma.annotations.entities.dlp.FileStoreDataProfile}
   */
  public static final class Builder extends com.google.protobuf.GeneratedMessage.Builder<Builder>
      implements
      // @@protoc_insertion_point(builder_implements:com.google.internal.spma.annotations.entities.dlp.FileStoreDataProfile)
      FileStoreDataProfileOrBuilder {
    private int bitField0;
    private java.lang.Object name_ = "";
    private java.lang.Object fileStorePath_ = "";

    // Construct using
    // com.google.internal.spma.annotations.entities.dlp.FileStoreDataProfile.newBuilder()
    private Builder() {}

    private Builder(com.google.protobuf.GeneratedMessage.BuilderParent parent) {
      super(parent);
    }

    public static com.google.protobuf.Descriptors.Descriptor getDescriptor() {
      return Dlp
          .internal_static_com_google_cloud_pso_bq_pii_classifier_entities_dlp_FileStoreDataProfile_descriptor;
    }

    @java.lang.Override
    protected com.google.protobuf.GeneratedMessage.FieldAccessorTable
        internalGetFieldAccessorTable() {
      return Dlp
          .internal_static_com_google_cloud_pso_bq_pii_classifier_entities_dlp_FileStoreDataProfile_fieldAccessorTable
          .ensureFieldAccessorsInitialized(
              FileStoreDataProfile.class, FileStoreDataProfile.Builder.class);
    }

    @java.lang.Override
    public Builder clear() {
      super.clear();
      bitField0 = 0;
      name_ = "";
      fileStorePath_ = "";
      return this;
    }

    @java.lang.Override
    public com.google.protobuf.Descriptors.Descriptor getDescriptorForType() {
      return Dlp
          .internal_static_com_google_cloud_pso_bq_pii_classifier_entities_dlp_FileStoreDataProfile_descriptor;
    }

    @java.lang.Override
    public FileStoreDataProfile getDefaultInstanceForType() {
      return FileStoreDataProfile.getDefaultInstance();
    }

    @java.lang.Override
    public FileStoreDataProfile build() {
      FileStoreDataProfile result = buildPartial();
      if (!result.isInitialized()) {
        throw newUninitializedMessageException(result);
      }
      return result;
    }

    @java.lang.Override
    public FileStoreDataProfile buildPartial() {
      FileStoreDataProfile result = new FileStoreDataProfile(this);
      if (bitField0 != 0) {
        buildPartial0(result);
      }
      onBuilt();
      return result;
    }

    private void buildPartial0(FileStoreDataProfile result) {
      int fromBitField0 = bitField0;
      if (((fromBitField0 & 0x00000001) != 0)) {
        result.name_ = name_;
      }
      if (((fromBitField0 & 0x00000002) != 0)) {
        result.fileStorePath_ = fileStorePath_;
      }
    }

    @java.lang.Override
    public Builder mergeFrom(com.google.protobuf.Message other) {
      if (other instanceof FileStoreDataProfile) {
        return mergeFrom((FileStoreDataProfile) other);
      } else {
        super.mergeFrom(other);
        return this;
      }
    }

    public Builder mergeFrom(FileStoreDataProfile other) {
      if (other == FileStoreDataProfile.getDefaultInstance()) {
        return this;
      }
      if (!other.getName().isEmpty()) {
        name_ = other.name_;
        bitField0 |= 0x00000001;
        onChanged();
      }
      if (!other.getFileStorePath().isEmpty()) {
        fileStorePath_ = other.fileStorePath_;
        bitField0 |= 0x00000002;
        onChanged();
      }
      this.mergeUnknownFields(other.getUnknownFields());
      onChanged();
      return this;
    }

    @java.lang.Override
    public boolean isInitialized() {
      return true;
    }

    @java.lang.Override
    public Builder mergeFrom(
        com.google.protobuf.CodedInputStream input,
        com.google.protobuf.ExtensionRegistryLite extensionRegistry)
        throws java.io.IOException {
      if (extensionRegistry == null) {
        throw new java.lang.NullPointerException();
      }
      try {
        boolean done = false;
        while (!done) {
          int tag = input.readTag();
          switch (tag) {
            case 0:
              done = true;
              break;
            case 10:
              {
                name_ = input.readStringRequireUtf8();
                bitField0 |= 0x00000001;
                break;
              } // case 10
            case 50:
              {
                fileStorePath_ = input.readStringRequireUtf8();
                bitField0 |= 0x00000002;
                break;
              } // case 50
            default:
              {
                if (!super.parseUnknownField(input, extensionRegistry, tag)) {
                  done = true; // was an end group tag
                }
                break;
              } // default:
          } // switch (tag)
        } // while (!done)
      } catch (com.google.protobuf.InvalidProtocolBufferException e) {
        throw e.unwrapIOException();
      } finally {
        onChanged();
      } // finally
      return this;
    }

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
    public java.lang.String getName() {
      java.lang.Object ref = name_;
      if (!(ref instanceof java.lang.String)) {
        com.google.protobuf.ByteString bs = (com.google.protobuf.ByteString) ref;
        java.lang.String s = bs.toStringUtf8();
        name_ = s;
        return s;
      } else {
        return (java.lang.String) ref;
      }
    }

    /**
     *
     *
     * <pre>
     * The name of the profile.
     * </pre>
     *
     * <code>string name = 1;</code>
     *
     * @param value The name to set.
     * @return This builder for chaining.
     */
    public Builder setName(java.lang.String value) {
      if (value == null) {
        throw new NullPointerException();
      }
      name_ = value;
      bitField0 |= 0x00000001;
      onChanged();
      return this;
    }

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
    public com.google.protobuf.ByteString getNameBytes() {
      java.lang.Object ref = name_;
      if (ref instanceof String) {
        com.google.protobuf.ByteString b =
            com.google.protobuf.ByteString.copyFromUtf8((java.lang.String) ref);
        name_ = b;
        return b;
      } else {
        return (com.google.protobuf.ByteString) ref;
      }
    }

    /**
     *
     *
     * <pre>
     * The name of the profile.
     * </pre>
     *
     * <code>string name = 1;</code>
     *
     * @param value The bytes for name to set.
     * @return This builder for chaining.
     */
    public Builder setNameBytes(com.google.protobuf.ByteString value) {
      if (value == null) {
        throw new NullPointerException();
      }
      checkByteStringIsUtf8(value);
      name_ = value;
      bitField0 |= 0x00000001;
      onChanged();
      return this;
    }

    /**
     *
     *
     * <pre>
     * The name of the profile.
     * </pre>
     *
     * <code>string name = 1;</code>
     *
     * @return This builder for chaining.
     */
    public Builder clearName() {
      name_ = getDefaultInstance().getName();
      bitField0 = (bitField0 & ~0x00000001);
      onChanged();
      return this;
    }

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
    public java.lang.String getFileStorePath() {
      java.lang.Object ref = fileStorePath_;
      if (!(ref instanceof java.lang.String)) {
        com.google.protobuf.ByteString bs = (com.google.protobuf.ByteString) ref;
        java.lang.String s = bs.toStringUtf8();
        fileStorePath_ = s;
        return s;
      } else {
        return (java.lang.String) ref;
      }
    }

    /**
     *
     *
     * <pre>
     * The path of the file store.
     * </pre>
     *
     * <code>string file_store_path = 6;</code>
     *
     * @param value The fileStorePath to set.
     * @return This builder for chaining.
     */
    public Builder setFileStorePath(java.lang.String value) {
      if (value == null) {
        throw new NullPointerException();
      }
      fileStorePath_ = value;
      bitField0 |= 0x00000002;
      onChanged();
      return this;
    }

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
    public com.google.protobuf.ByteString getFileStorePathBytes() {
      java.lang.Object ref = fileStorePath_;
      if (ref instanceof String) {
        com.google.protobuf.ByteString b =
            com.google.protobuf.ByteString.copyFromUtf8((java.lang.String) ref);
        fileStorePath_ = b;
        return b;
      } else {
        return (com.google.protobuf.ByteString) ref;
      }
    }

    /**
     *
     *
     * <pre>
     * The path of the file store.
     * </pre>
     *
     * <code>string file_store_path = 6;</code>
     *
     * @param value The bytes for fileStorePath to set.
     * @return This builder for chaining.
     */
    public Builder setFileStorePathBytes(com.google.protobuf.ByteString value) {
      if (value == null) {
        throw new NullPointerException();
      }
      checkByteStringIsUtf8(value);
      fileStorePath_ = value;
      bitField0 |= 0x00000002;
      onChanged();
      return this;
    }

    /**
     *
     *
     * <pre>
     * The path of the file store.
     * </pre>
     *
     * <code>string file_store_path = 6;</code>
     *
     * @return This builder for chaining.
     */
    public Builder clearFileStorePath() {
      fileStorePath_ = getDefaultInstance().getFileStorePath();
      bitField0 = (bitField0 & ~0x00000002);
      onChanged();
      return this;
    }

    // @@protoc_insertion_point(builder_scope:com.google.internal.spma.annotations.entities.dlp.FileStoreDataProfile)
  }
}
