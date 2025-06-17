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
 * The message that will be published to a Pub/Sub topic.
 * To receive a message of protocol buffer schema type, convert the message data
 * to an object of this proto class.
 * https://cloud.google.com/pubsub/docs/samples/pubsub-subscribe-proto-messages
 * </pre>
 *
 * Protobuf type {@code com.google.internal.spma.annotations.entities.dlp.DataProfilePubSubMessage}
 */
public final class DataProfilePubSubMessage extends com.google.protobuf.GeneratedMessage
    implements
    // @@protoc_insertion_point(message_implements:com.google.internal.spma.annotations.entities.dlp.DataProfilePubSubMessage)
    DataProfilePubSubMessageOrBuilder {
  public static final int PROFILE_FIELD_NUMBER = 1;
  public static final int EVENT_FIELD_NUMBER = 2;
  public static final int FILE_STORE_PROFILE_FIELD_NUMBER = 3;
  private static final long serialVersionUID = 0L;
  // @@protoc_insertion_point(class_scope:com.google.internal.spma.annotations.entities.dlp.DataProfilePubSubMessage)
  private static final DataProfilePubSubMessage DEFAULT_INSTANCE;
  private static final com.google.protobuf.Parser<DataProfilePubSubMessage> PARSER =
      new com.google.protobuf.AbstractParser<DataProfilePubSubMessage>() {
        @java.lang.Override
        public DataProfilePubSubMessage parsePartialFrom(
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
        DataProfilePubSubMessage.class.getName());
  }

  static {
    DEFAULT_INSTANCE = new DataProfilePubSubMessage();
  }

  private int bitField0_;
  private TableDataProfile profile_;
  private int event_ = 0;
  private FileStoreDataProfile fileStoreProfile_;
  private byte memoizedIsInitialized = -1;

  // Use DataProfilePubSubMessage.newBuilder() to construct.
  private DataProfilePubSubMessage(com.google.protobuf.GeneratedMessage.Builder<?> builder) {
    super(builder);
  }

  private DataProfilePubSubMessage() {
    event_ = 0;
  }

  public static com.google.protobuf.Descriptors.Descriptor getDescriptor() {
    return Dlp
        .internal_static_com_google_cloud_pso_bq_pii_classifier_entities_dlp_DataProfilePubSubMessage_descriptor;
  }

  public static DataProfilePubSubMessage parseFrom(java.nio.ByteBuffer data)
      throws com.google.protobuf.InvalidProtocolBufferException {
    return PARSER.parseFrom(data);
  }

  public static DataProfilePubSubMessage parseFrom(
      java.nio.ByteBuffer data, com.google.protobuf.ExtensionRegistryLite extensionRegistry)
      throws com.google.protobuf.InvalidProtocolBufferException {
    return PARSER.parseFrom(data, extensionRegistry);
  }

  public static DataProfilePubSubMessage parseFrom(com.google.protobuf.ByteString data)
      throws com.google.protobuf.InvalidProtocolBufferException {
    return PARSER.parseFrom(data);
  }

  public static DataProfilePubSubMessage parseFrom(
      com.google.protobuf.ByteString data,
      com.google.protobuf.ExtensionRegistryLite extensionRegistry)
      throws com.google.protobuf.InvalidProtocolBufferException {
    return PARSER.parseFrom(data, extensionRegistry);
  }

  public static DataProfilePubSubMessage parseFrom(byte[] data)
      throws com.google.protobuf.InvalidProtocolBufferException {
    return PARSER.parseFrom(data);
  }

  public static DataProfilePubSubMessage parseFrom(
      byte[] data, com.google.protobuf.ExtensionRegistryLite extensionRegistry)
      throws com.google.protobuf.InvalidProtocolBufferException {
    return PARSER.parseFrom(data, extensionRegistry);
  }

  public static DataProfilePubSubMessage parseFrom(java.io.InputStream input)
      throws java.io.IOException {
    return com.google.protobuf.GeneratedMessage.parseWithIOException(PARSER, input);
  }

  public static DataProfilePubSubMessage parseFrom(
      java.io.InputStream input, com.google.protobuf.ExtensionRegistryLite extensionRegistry)
      throws java.io.IOException {
    return com.google.protobuf.GeneratedMessage.parseWithIOException(
        PARSER, input, extensionRegistry);
  }

  public static DataProfilePubSubMessage parseDelimitedFrom(java.io.InputStream input)
      throws java.io.IOException {
    return com.google.protobuf.GeneratedMessage.parseDelimitedWithIOException(PARSER, input);
  }

  public static DataProfilePubSubMessage parseDelimitedFrom(
      java.io.InputStream input, com.google.protobuf.ExtensionRegistryLite extensionRegistry)
      throws java.io.IOException {
    return com.google.protobuf.GeneratedMessage.parseDelimitedWithIOException(
        PARSER, input, extensionRegistry);
  }

  public static DataProfilePubSubMessage parseFrom(com.google.protobuf.CodedInputStream input)
      throws java.io.IOException {
    return com.google.protobuf.GeneratedMessage.parseWithIOException(PARSER, input);
  }

  public static DataProfilePubSubMessage parseFrom(
      com.google.protobuf.CodedInputStream input,
      com.google.protobuf.ExtensionRegistryLite extensionRegistry)
      throws java.io.IOException {
    return com.google.protobuf.GeneratedMessage.parseWithIOException(
        PARSER, input, extensionRegistry);
  }

  public static Builder newBuilder() {
    return DEFAULT_INSTANCE.toBuilder();
  }

  public static Builder newBuilder(DataProfilePubSubMessage prototype) {
    return DEFAULT_INSTANCE.toBuilder().mergeFrom(prototype);
  }

  public static DataProfilePubSubMessage getDefaultInstance() {
    return DEFAULT_INSTANCE;
  }

  public static com.google.protobuf.Parser<DataProfilePubSubMessage> parser() {
    return PARSER;
  }

  @java.lang.Override
  protected com.google.protobuf.GeneratedMessage.FieldAccessorTable
      internalGetFieldAccessorTable() {
    return Dlp
        .internal_static_com_google_cloud_pso_bq_pii_classifier_entities_dlp_DataProfilePubSubMessage_fieldAccessorTable
        .ensureFieldAccessorsInitialized(
            DataProfilePubSubMessage.class, DataProfilePubSubMessage.Builder.class);
  }

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
  @java.lang.Override
  public boolean hasProfile() {
    return ((bitField0_ & 0x00000001) != 0);
  }

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
  @java.lang.Override
  public TableDataProfile getProfile() {
    return profile_ == null ? TableDataProfile.getDefaultInstance() : profile_;
  }

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
  @java.lang.Override
  public TableDataProfileOrBuilder getProfileOrBuilder() {
    return profile_ == null ? TableDataProfile.getDefaultInstance() : profile_;
  }

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
  @java.lang.Override
  public int getEventValue() {
    return event_;
  }

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
  @java.lang.Override
  public DataProfileAction.EventType getEvent() {
    DataProfileAction.EventType result = DataProfileAction.EventType.forNumber(event_);
    return result == null ? DataProfileAction.EventType.UNRECOGNIZED : result;
  }

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
  @java.lang.Override
  public boolean hasFileStoreProfile() {
    return ((bitField0_ & 0x00000002) != 0);
  }

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
  @java.lang.Override
  public FileStoreDataProfile getFileStoreProfile() {
    return fileStoreProfile_ == null
        ? FileStoreDataProfile.getDefaultInstance()
        : fileStoreProfile_;
  }

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
  @java.lang.Override
  public FileStoreDataProfileOrBuilder getFileStoreProfileOrBuilder() {
    return fileStoreProfile_ == null
        ? FileStoreDataProfile.getDefaultInstance()
        : fileStoreProfile_;
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
    if (((bitField0_ & 0x00000001) != 0)) {
      output.writeMessage(1, getProfile());
    }
    if (event_ != DataProfileAction.EventType.EVENT_TYPE_UNSPECIFIED.getNumber()) {
      output.writeEnum(2, event_);
    }
    if (((bitField0_ & 0x00000002) != 0)) {
      output.writeMessage(3, getFileStoreProfile());
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
    if (((bitField0_ & 0x00000001) != 0)) {
      size += com.google.protobuf.CodedOutputStream.computeMessageSize(1, getProfile());
    }
    if (event_ != DataProfileAction.EventType.EVENT_TYPE_UNSPECIFIED.getNumber()) {
      size += com.google.protobuf.CodedOutputStream.computeEnumSize(2, event_);
    }
    if (((bitField0_ & 0x00000002) != 0)) {
      size += com.google.protobuf.CodedOutputStream.computeMessageSize(3, getFileStoreProfile());
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
    if (!(obj instanceof DataProfilePubSubMessage other)) {
      return super.equals(obj);
    }

    if (hasProfile() != other.hasProfile()) {
      return false;
    }
    if (hasProfile()) {
      if (!getProfile().equals(other.getProfile())) {
        return false;
      }
    }
    if (event_ != other.event_) {
      return false;
    }
    if (hasFileStoreProfile() != other.hasFileStoreProfile()) {
      return false;
    }
    if (hasFileStoreProfile()) {
      if (!getFileStoreProfile().equals(other.getFileStoreProfile())) {
        return false;
      }
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
    if (hasProfile()) {
      hash = (37 * hash) + PROFILE_FIELD_NUMBER;
      hash = (53 * hash) + getProfile().hashCode();
    }
    hash = (37 * hash) + EVENT_FIELD_NUMBER;
    hash = (53 * hash) + event_;
    if (hasFileStoreProfile()) {
      hash = (37 * hash) + FILE_STORE_PROFILE_FIELD_NUMBER;
      hash = (53 * hash) + getFileStoreProfile().hashCode();
    }
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
  public com.google.protobuf.Parser<DataProfilePubSubMessage> getParserForType() {
    return PARSER;
  }

  @java.lang.Override
  public DataProfilePubSubMessage getDefaultInstanceForType() {
    return DEFAULT_INSTANCE;
  }

  /**
   *
   *
   * <pre>
   * The message that will be published to a Pub/Sub topic.
   * To receive a message of protocol buffer schema type, convert the message data
   * to an object of this proto class.
   * https://cloud.google.com/pubsub/docs/samples/pubsub-subscribe-proto-messages
   * </pre>
   *
   * Protobuf type {@code
   * com.google.internal.spma.annotations.entities.dlp.DataProfilePubSubMessage}
   */
  public static final class Builder extends com.google.protobuf.GeneratedMessage.Builder<Builder>
      implements
      // @@protoc_insertion_point(builder_implements:com.google.internal.spma.annotations.entities.dlp.DataProfilePubSubMessage)
      DataProfilePubSubMessageOrBuilder {
    private int bitField0;
    private TableDataProfile profile_;
    private com.google.protobuf.SingleFieldBuilder<
            TableDataProfile, TableDataProfile.Builder, TableDataProfileOrBuilder>
        profileBuilder_;
    private int event_ = 0;
    private FileStoreDataProfile fileStoreProfile_;
    private com.google.protobuf.SingleFieldBuilder<
            FileStoreDataProfile, FileStoreDataProfile.Builder, FileStoreDataProfileOrBuilder>
        fileStoreProfileBuilder_;

    // Construct using
    // com.google.internal.spma.annotations.entities.dlp.DataProfilePubSubMessage.newBuilder()
    private Builder() {
      maybeForceBuilderInitialization();
    }

    private Builder(com.google.protobuf.GeneratedMessage.BuilderParent parent) {
      super(parent);
      maybeForceBuilderInitialization();
    }

    public static com.google.protobuf.Descriptors.Descriptor getDescriptor() {
      return Dlp
          .internal_static_com_google_cloud_pso_bq_pii_classifier_entities_dlp_DataProfilePubSubMessage_descriptor;
    }

    @java.lang.Override
    protected com.google.protobuf.GeneratedMessage.FieldAccessorTable
        internalGetFieldAccessorTable() {
      return Dlp
          .internal_static_com_google_cloud_pso_bq_pii_classifier_entities_dlp_DataProfilePubSubMessage_fieldAccessorTable
          .ensureFieldAccessorsInitialized(
              DataProfilePubSubMessage.class, DataProfilePubSubMessage.Builder.class);
    }

    private void maybeForceBuilderInitialization() {
      if (com.google.protobuf.GeneratedMessage.alwaysUseFieldBuilders) {
        getProfileFieldBuilder();
        getFileStoreProfileFieldBuilder();
      }
    }

    @java.lang.Override
    public Builder clear() {
      super.clear();
      bitField0 = 0;
      profile_ = null;
      if (profileBuilder_ != null) {
        profileBuilder_.dispose();
        profileBuilder_ = null;
      }
      event_ = 0;
      fileStoreProfile_ = null;
      if (fileStoreProfileBuilder_ != null) {
        fileStoreProfileBuilder_.dispose();
        fileStoreProfileBuilder_ = null;
      }
      return this;
    }

    @java.lang.Override
    public com.google.protobuf.Descriptors.Descriptor getDescriptorForType() {
      return Dlp
          .internal_static_com_google_cloud_pso_bq_pii_classifier_entities_dlp_DataProfilePubSubMessage_descriptor;
    }

    @java.lang.Override
    public DataProfilePubSubMessage getDefaultInstanceForType() {
      return DataProfilePubSubMessage.getDefaultInstance();
    }

    @java.lang.Override
    public DataProfilePubSubMessage build() {
      DataProfilePubSubMessage result = buildPartial();
      if (!result.isInitialized()) {
        throw newUninitializedMessageException(result);
      }
      return result;
    }

    @java.lang.Override
    public DataProfilePubSubMessage buildPartial() {
      DataProfilePubSubMessage result = new DataProfilePubSubMessage(this);
      if (bitField0 != 0) {
        buildPartial0(result);
      }
      onBuilt();
      return result;
    }

    private void buildPartial0(DataProfilePubSubMessage result) {
      int fromBitField0 = bitField0;
      int toBitField0 = 0;
      if (((fromBitField0 & 0x00000001) != 0)) {
        result.profile_ = profileBuilder_ == null ? profile_ : profileBuilder_.build();
        toBitField0 |= 0x00000001;
      }
      if (((fromBitField0 & 0x00000002) != 0)) {
        result.event_ = event_;
      }
      if (((fromBitField0 & 0x00000004) != 0)) {
        result.fileStoreProfile_ =
            fileStoreProfileBuilder_ == null ? fileStoreProfile_ : fileStoreProfileBuilder_.build();
        toBitField0 |= 0x00000002;
      }
      result.bitField0_ |= toBitField0;
    }

    @java.lang.Override
    public Builder mergeFrom(com.google.protobuf.Message other) {
      if (other instanceof DataProfilePubSubMessage) {
        return mergeFrom((DataProfilePubSubMessage) other);
      } else {
        super.mergeFrom(other);
        return this;
      }
    }

    public Builder mergeFrom(DataProfilePubSubMessage other) {
      if (other == DataProfilePubSubMessage.getDefaultInstance()) {
        return this;
      }
      if (other.hasProfile()) {
        mergeProfile(other.getProfile());
      }
      if (other.event_ != 0) {
        setEventValue(other.getEventValue());
      }
      if (other.hasFileStoreProfile()) {
        mergeFileStoreProfile(other.getFileStoreProfile());
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
                input.readMessage(getProfileFieldBuilder().getBuilder(), extensionRegistry);
                bitField0 |= 0x00000001;
                break;
              } // case 10
            case 16:
              {
                event_ = input.readEnum();
                bitField0 |= 0x00000002;
                break;
              } // case 16
            case 26:
              {
                input.readMessage(
                    getFileStoreProfileFieldBuilder().getBuilder(), extensionRegistry);
                bitField0 |= 0x00000004;
                break;
              } // case 26
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
     * If `DetailLevel` is `TABLE_PROFILE` this will be fully populated.
     * Otherwise, if `DetailLevel` is `RESOURCE_NAME`, then only `name` and
     * `full_resource` will be populated.
     * </pre>
     *
     * <code>.com.google.internal.spma.annotations.entities.dlp.TableDataProfile profile = 1;
     * </code>
     *
     * @return Whether the profile field is set.
     */
    public boolean hasProfile() {
      return ((bitField0 & 0x00000001) != 0);
    }

    /**
     *
     *
     * <pre>
     * If `DetailLevel` is `TABLE_PROFILE` this will be fully populated.
     * Otherwise, if `DetailLevel` is `RESOURCE_NAME`, then only `name` and
     * `full_resource` will be populated.
     * </pre>
     *
     * <code>.com.google.internal.spma.annotations.entities.dlp.TableDataProfile profile = 1;
     * </code>
     *
     * @return The profile.
     */
    public TableDataProfile getProfile() {
      if (profileBuilder_ == null) {
        return profile_ == null ? TableDataProfile.getDefaultInstance() : profile_;
      } else {
        return profileBuilder_.getMessage();
      }
    }

    /**
     *
     *
     * <pre>
     * If `DetailLevel` is `TABLE_PROFILE` this will be fully populated.
     * Otherwise, if `DetailLevel` is `RESOURCE_NAME`, then only `name` and
     * `full_resource` will be populated.
     * </pre>
     *
     * <code>.com.google.internal.spma.annotations.entities.dlp.TableDataProfile profile = 1;
     * </code>
     */
    public Builder setProfile(TableDataProfile value) {
      if (profileBuilder_ == null) {
        if (value == null) {
          throw new NullPointerException();
        }
        profile_ = value;
      } else {
        profileBuilder_.setMessage(value);
      }
      bitField0 |= 0x00000001;
      onChanged();
      return this;
    }

    /**
     *
     *
     * <pre>
     * If `DetailLevel` is `TABLE_PROFILE` this will be fully populated.
     * Otherwise, if `DetailLevel` is `RESOURCE_NAME`, then only `name` and
     * `full_resource` will be populated.
     * </pre>
     *
     * <code>.com.google.internal.spma.annotations.entities.dlp.TableDataProfile profile = 1;
     * </code>
     */
    public Builder setProfile(TableDataProfile.Builder builderForValue) {
      if (profileBuilder_ == null) {
        profile_ = builderForValue.build();
      } else {
        profileBuilder_.setMessage(builderForValue.build());
      }
      bitField0 |= 0x00000001;
      onChanged();
      return this;
    }

    /**
     *
     *
     * <pre>
     * If `DetailLevel` is `TABLE_PROFILE` this will be fully populated.
     * Otherwise, if `DetailLevel` is `RESOURCE_NAME`, then only `name` and
     * `full_resource` will be populated.
     * </pre>
     *
     * <code>.com.google.internal.spma.annotations.entities.dlp.TableDataProfile profile = 1;
     * </code>
     */
    public Builder mergeProfile(TableDataProfile value) {
      if (profileBuilder_ == null) {
        if (((bitField0 & 0x00000001) != 0)
            && profile_ != null
            && profile_ != TableDataProfile.getDefaultInstance()) {
          getProfileBuilder().mergeFrom(value);
        } else {
          profile_ = value;
        }
      } else {
        profileBuilder_.mergeFrom(value);
      }
      if (profile_ != null) {
        bitField0 |= 0x00000001;
        onChanged();
      }
      return this;
    }

    /**
     *
     *
     * <pre>
     * If `DetailLevel` is `TABLE_PROFILE` this will be fully populated.
     * Otherwise, if `DetailLevel` is `RESOURCE_NAME`, then only `name` and
     * `full_resource` will be populated.
     * </pre>
     *
     * <code>.com.google.internal.spma.annotations.entities.dlp.TableDataProfile profile = 1;
     * </code>
     */
    public Builder clearProfile() {
      bitField0 = (bitField0 & ~0x00000001);
      profile_ = null;
      if (profileBuilder_ != null) {
        profileBuilder_.dispose();
        profileBuilder_ = null;
      }
      onChanged();
      return this;
    }

    /**
     *
     *
     * <pre>
     * If `DetailLevel` is `TABLE_PROFILE` this will be fully populated.
     * Otherwise, if `DetailLevel` is `RESOURCE_NAME`, then only `name` and
     * `full_resource` will be populated.
     * </pre>
     *
     * <code>.com.google.internal.spma.annotations.entities.dlp.TableDataProfile profile = 1;
     * </code>
     */
    public TableDataProfile.Builder getProfileBuilder() {
      bitField0 |= 0x00000001;
      onChanged();
      return getProfileFieldBuilder().getBuilder();
    }

    /**
     *
     *
     * <pre>
     * If `DetailLevel` is `TABLE_PROFILE` this will be fully populated.
     * Otherwise, if `DetailLevel` is `RESOURCE_NAME`, then only `name` and
     * `full_resource` will be populated.
     * </pre>
     *
     * <code>.com.google.internal.spma.annotations.entities.dlp.TableDataProfile profile = 1;
     * </code>
     */
    public TableDataProfileOrBuilder getProfileOrBuilder() {
      if (profileBuilder_ != null) {
        return profileBuilder_.getMessageOrBuilder();
      } else {
        return profile_ == null ? TableDataProfile.getDefaultInstance() : profile_;
      }
    }

    /**
     *
     *
     * <pre>
     * If `DetailLevel` is `TABLE_PROFILE` this will be fully populated.
     * Otherwise, if `DetailLevel` is `RESOURCE_NAME`, then only `name` and
     * `full_resource` will be populated.
     * </pre>
     *
     * <code>.com.google.internal.spma.annotations.entities.dlp.TableDataProfile profile = 1;
     * </code>
     */
    private com.google.protobuf.SingleFieldBuilder<
            TableDataProfile, TableDataProfile.Builder, TableDataProfileOrBuilder>
        getProfileFieldBuilder() {
      if (profileBuilder_ == null) {
        profileBuilder_ =
            new com.google.protobuf.SingleFieldBuilder<
                TableDataProfile, TableDataProfile.Builder, TableDataProfileOrBuilder>(
                getProfile(), getParentForChildren(), isClean());
        profile_ = null;
      }
      return profileBuilder_;
    }

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
    @java.lang.Override
    public int getEventValue() {
      return event_;
    }

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
     * @param value The enum numeric value on the wire for event to set.
     * @return This builder for chaining.
     */
    public Builder setEventValue(int value) {
      event_ = value;
      bitField0 |= 0x00000002;
      onChanged();
      return this;
    }

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
    @java.lang.Override
    public DataProfileAction.EventType getEvent() {
      DataProfileAction.EventType result = DataProfileAction.EventType.forNumber(event_);
      return result == null ? DataProfileAction.EventType.UNRECOGNIZED : result;
    }

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
     * @param value The event to set.
     * @return This builder for chaining.
     */
    public Builder setEvent(DataProfileAction.EventType value) {
      if (value == null) {
        throw new NullPointerException();
      }
      bitField0 |= 0x00000002;
      event_ = value.getNumber();
      onChanged();
      return this;
    }

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
     * @return This builder for chaining.
     */
    public Builder clearEvent() {
      bitField0 = (bitField0 & ~0x00000002);
      event_ = 0;
      onChanged();
      return this;
    }

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
    public boolean hasFileStoreProfile() {
      return ((bitField0 & 0x00000004) != 0);
    }

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
    public FileStoreDataProfile getFileStoreProfile() {
      if (fileStoreProfileBuilder_ == null) {
        return fileStoreProfile_ == null
            ? FileStoreDataProfile.getDefaultInstance()
            : fileStoreProfile_;
      } else {
        return fileStoreProfileBuilder_.getMessage();
      }
    }

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
    public Builder setFileStoreProfile(FileStoreDataProfile value) {
      if (fileStoreProfileBuilder_ == null) {
        if (value == null) {
          throw new NullPointerException();
        }
        fileStoreProfile_ = value;
      } else {
        fileStoreProfileBuilder_.setMessage(value);
      }
      bitField0 |= 0x00000004;
      onChanged();
      return this;
    }

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
    public Builder setFileStoreProfile(FileStoreDataProfile.Builder builderForValue) {
      if (fileStoreProfileBuilder_ == null) {
        fileStoreProfile_ = builderForValue.build();
      } else {
        fileStoreProfileBuilder_.setMessage(builderForValue.build());
      }
      bitField0 |= 0x00000004;
      onChanged();
      return this;
    }

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
    public Builder mergeFileStoreProfile(FileStoreDataProfile value) {
      if (fileStoreProfileBuilder_ == null) {
        if (((bitField0 & 0x00000004) != 0)
            && fileStoreProfile_ != null
            && fileStoreProfile_ != FileStoreDataProfile.getDefaultInstance()) {
          getFileStoreProfileBuilder().mergeFrom(value);
        } else {
          fileStoreProfile_ = value;
        }
      } else {
        fileStoreProfileBuilder_.mergeFrom(value);
      }
      if (fileStoreProfile_ != null) {
        bitField0 |= 0x00000004;
        onChanged();
      }
      return this;
    }

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
    public Builder clearFileStoreProfile() {
      bitField0 = (bitField0 & ~0x00000004);
      fileStoreProfile_ = null;
      if (fileStoreProfileBuilder_ != null) {
        fileStoreProfileBuilder_.dispose();
        fileStoreProfileBuilder_ = null;
      }
      onChanged();
      return this;
    }

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
    public FileStoreDataProfile.Builder getFileStoreProfileBuilder() {
      bitField0 |= 0x00000004;
      onChanged();
      return getFileStoreProfileFieldBuilder().getBuilder();
    }

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
    public FileStoreDataProfileOrBuilder getFileStoreProfileOrBuilder() {
      if (fileStoreProfileBuilder_ != null) {
        return fileStoreProfileBuilder_.getMessageOrBuilder();
      } else {
        return fileStoreProfile_ == null
            ? FileStoreDataProfile.getDefaultInstance()
            : fileStoreProfile_;
      }
    }

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
    private com.google.protobuf.SingleFieldBuilder<
            FileStoreDataProfile, FileStoreDataProfile.Builder, FileStoreDataProfileOrBuilder>
        getFileStoreProfileFieldBuilder() {
      if (fileStoreProfileBuilder_ == null) {
        fileStoreProfileBuilder_ =
            new com.google.protobuf.SingleFieldBuilder<
                FileStoreDataProfile, FileStoreDataProfile.Builder, FileStoreDataProfileOrBuilder>(
                getFileStoreProfile(), getParentForChildren(), isClean());
        fileStoreProfile_ = null;
      }
      return fileStoreProfileBuilder_;
    }

    // @@protoc_insertion_point(builder_scope:com.google.internal.spma.annotations.entities.dlp.DataProfilePubSubMessage)
  }
}
