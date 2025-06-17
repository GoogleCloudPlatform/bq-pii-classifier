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
 * The profile for a scanned table.
 * </pre>
 *
 * Protobuf type {@code com.google.internal.spma.annotations.entities.dlp.TableDataProfile}
 */
public final class TableDataProfile extends com.google.protobuf.GeneratedMessage
    implements
    // @@protoc_insertion_point(message_implements:com.google.internal.spma.annotations.entities.dlp.TableDataProfile)
    TableDataProfileOrBuilder {
  public static final int NAME_FIELD_NUMBER = 1;
  public static final int FULL_RESOURCE_FIELD_NUMBER = 3;
  private static final long serialVersionUID = 0L;
  // @@protoc_insertion_point(class_scope:com.google.internal.spma.annotations.entities.dlp.TableDataProfile)
  private static final TableDataProfile DEFAULT_INSTANCE;
  private static final com.google.protobuf.Parser<TableDataProfile> PARSER =
      new com.google.protobuf.AbstractParser<TableDataProfile>() {
        @java.lang.Override
        public TableDataProfile parsePartialFrom(
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
        TableDataProfile.class.getName());
  }

  static {
    DEFAULT_INSTANCE = new TableDataProfile();
  }

  @SuppressWarnings("serial")
  private volatile java.lang.Object name_ = "";

  @SuppressWarnings("serial")
  private volatile java.lang.Object fullResource_ = "";

  private byte memoizedIsInitialized = -1;

  // Use TableDataProfile.newBuilder() to construct.
  private TableDataProfile(com.google.protobuf.GeneratedMessage.Builder<?> builder) {
    super(builder);
  }

  private TableDataProfile() {
    name_ = "";
    fullResource_ = "";
  }

  public static com.google.protobuf.Descriptors.Descriptor getDescriptor() {
    return Dlp
        .internal_static_com_google_cloud_pso_bq_pii_classifier_entities_dlp_TableDataProfile_descriptor;
  }

  public static TableDataProfile parseFrom(java.nio.ByteBuffer data)
      throws com.google.protobuf.InvalidProtocolBufferException {
    return PARSER.parseFrom(data);
  }

  public static TableDataProfile parseFrom(
      java.nio.ByteBuffer data, com.google.protobuf.ExtensionRegistryLite extensionRegistry)
      throws com.google.protobuf.InvalidProtocolBufferException {
    return PARSER.parseFrom(data, extensionRegistry);
  }

  public static TableDataProfile parseFrom(com.google.protobuf.ByteString data)
      throws com.google.protobuf.InvalidProtocolBufferException {
    return PARSER.parseFrom(data);
  }

  public static TableDataProfile parseFrom(
      com.google.protobuf.ByteString data,
      com.google.protobuf.ExtensionRegistryLite extensionRegistry)
      throws com.google.protobuf.InvalidProtocolBufferException {
    return PARSER.parseFrom(data, extensionRegistry);
  }

  public static TableDataProfile parseFrom(byte[] data)
      throws com.google.protobuf.InvalidProtocolBufferException {
    return PARSER.parseFrom(data);
  }

  public static TableDataProfile parseFrom(
      byte[] data, com.google.protobuf.ExtensionRegistryLite extensionRegistry)
      throws com.google.protobuf.InvalidProtocolBufferException {
    return PARSER.parseFrom(data, extensionRegistry);
  }

  public static TableDataProfile parseFrom(java.io.InputStream input) throws java.io.IOException {
    return com.google.protobuf.GeneratedMessage.parseWithIOException(PARSER, input);
  }

  public static TableDataProfile parseFrom(
      java.io.InputStream input, com.google.protobuf.ExtensionRegistryLite extensionRegistry)
      throws java.io.IOException {
    return com.google.protobuf.GeneratedMessage.parseWithIOException(
        PARSER, input, extensionRegistry);
  }

  public static TableDataProfile parseDelimitedFrom(java.io.InputStream input)
      throws java.io.IOException {
    return com.google.protobuf.GeneratedMessage.parseDelimitedWithIOException(PARSER, input);
  }

  public static TableDataProfile parseDelimitedFrom(
      java.io.InputStream input, com.google.protobuf.ExtensionRegistryLite extensionRegistry)
      throws java.io.IOException {
    return com.google.protobuf.GeneratedMessage.parseDelimitedWithIOException(
        PARSER, input, extensionRegistry);
  }

  public static TableDataProfile parseFrom(com.google.protobuf.CodedInputStream input)
      throws java.io.IOException {
    return com.google.protobuf.GeneratedMessage.parseWithIOException(PARSER, input);
  }

  public static TableDataProfile parseFrom(
      com.google.protobuf.CodedInputStream input,
      com.google.protobuf.ExtensionRegistryLite extensionRegistry)
      throws java.io.IOException {
    return com.google.protobuf.GeneratedMessage.parseWithIOException(
        PARSER, input, extensionRegistry);
  }

  public static Builder newBuilder() {
    return DEFAULT_INSTANCE.toBuilder();
  }

  public static Builder newBuilder(TableDataProfile prototype) {
    return DEFAULT_INSTANCE.toBuilder().mergeFrom(prototype);
  }

  public static TableDataProfile getDefaultInstance() {
    return DEFAULT_INSTANCE;
  }

  public static com.google.protobuf.Parser<TableDataProfile> parser() {
    return PARSER;
  }

  @java.lang.Override
  protected com.google.protobuf.GeneratedMessage.FieldAccessorTable
      internalGetFieldAccessorTable() {
    return Dlp
        .internal_static_com_google_cloud_pso_bq_pii_classifier_entities_dlp_TableDataProfile_fieldAccessorTable
        .ensureFieldAccessorsInitialized(TableDataProfile.class, TableDataProfile.Builder.class);
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
   * The resource name of the table.
   * https://cloud.google.com/apis/design/resource_names#full_resource_name
   * </pre>
   *
   * <code>string full_resource = 3;</code>
   *
   * @return The fullResource.
   */
  @java.lang.Override
  public java.lang.String getFullResource() {
    java.lang.Object ref = fullResource_;
    if (ref instanceof java.lang.String) {
      return (java.lang.String) ref;
    } else {
      com.google.protobuf.ByteString bs = (com.google.protobuf.ByteString) ref;
      java.lang.String s = bs.toStringUtf8();
      fullResource_ = s;
      return s;
    }
  }

  /**
   *
   *
   * <pre>
   * The resource name of the table.
   * https://cloud.google.com/apis/design/resource_names#full_resource_name
   * </pre>
   *
   * <code>string full_resource = 3;</code>
   *
   * @return The bytes for fullResource.
   */
  @java.lang.Override
  public com.google.protobuf.ByteString getFullResourceBytes() {
    java.lang.Object ref = fullResource_;
    if (ref instanceof java.lang.String) {
      com.google.protobuf.ByteString b =
          com.google.protobuf.ByteString.copyFromUtf8((java.lang.String) ref);
      fullResource_ = b;
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
    if (!com.google.protobuf.GeneratedMessage.isStringEmpty(fullResource_)) {
      com.google.protobuf.GeneratedMessage.writeString(output, 3, fullResource_);
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
    if (!com.google.protobuf.GeneratedMessage.isStringEmpty(fullResource_)) {
      size += com.google.protobuf.GeneratedMessage.computeStringSize(3, fullResource_);
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
    if (!(obj instanceof TableDataProfile other)) {
      return super.equals(obj);
    }

    if (!getName().equals(other.getName())) {
      return false;
    }
    if (!getFullResource().equals(other.getFullResource())) {
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
    hash = (37 * hash) + FULL_RESOURCE_FIELD_NUMBER;
    hash = (53 * hash) + getFullResource().hashCode();
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
  public com.google.protobuf.Parser<TableDataProfile> getParserForType() {
    return PARSER;
  }

  @java.lang.Override
  public TableDataProfile getDefaultInstanceForType() {
    return DEFAULT_INSTANCE;
  }

  /**
   *
   *
   * <pre>
   * The profile for a scanned table.
   * </pre>
   *
   * Protobuf type {@code com.google.internal.spma.annotations.entities.dlp.TableDataProfile}
   */
  public static final class Builder extends com.google.protobuf.GeneratedMessage.Builder<Builder>
      implements
      // @@protoc_insertion_point(builder_implements:com.google.internal.spma.annotations.entities.dlp.TableDataProfile)
      TableDataProfileOrBuilder {
    private int bitField0;
    private java.lang.Object name_ = "";
    private java.lang.Object fullResource_ = "";

    // Construct using
    // com.google.internal.spma.annotations.entities.dlp.TableDataProfile.newBuilder()
    private Builder() {}

    private Builder(com.google.protobuf.GeneratedMessage.BuilderParent parent) {
      super(parent);
    }

    public static com.google.protobuf.Descriptors.Descriptor getDescriptor() {
      return Dlp
          .internal_static_com_google_cloud_pso_bq_pii_classifier_entities_dlp_TableDataProfile_descriptor;
    }

    @java.lang.Override
    protected com.google.protobuf.GeneratedMessage.FieldAccessorTable
        internalGetFieldAccessorTable() {
      return Dlp
          .internal_static_com_google_cloud_pso_bq_pii_classifier_entities_dlp_TableDataProfile_fieldAccessorTable
          .ensureFieldAccessorsInitialized(TableDataProfile.class, TableDataProfile.Builder.class);
    }

    @java.lang.Override
    public Builder clear() {
      super.clear();
      bitField0 = 0;
      name_ = "";
      fullResource_ = "";
      return this;
    }

    @java.lang.Override
    public com.google.protobuf.Descriptors.Descriptor getDescriptorForType() {
      return Dlp
          .internal_static_com_google_cloud_pso_bq_pii_classifier_entities_dlp_TableDataProfile_descriptor;
    }

    @java.lang.Override
    public TableDataProfile getDefaultInstanceForType() {
      return TableDataProfile.getDefaultInstance();
    }

    @java.lang.Override
    public TableDataProfile build() {
      TableDataProfile result = buildPartial();
      if (!result.isInitialized()) {
        throw newUninitializedMessageException(result);
      }
      return result;
    }

    @java.lang.Override
    public TableDataProfile buildPartial() {
      TableDataProfile result = new TableDataProfile(this);
      if (bitField0 != 0) {
        buildPartial0(result);
      }
      onBuilt();
      return result;
    }

    private void buildPartial0(TableDataProfile result) {
      int fromBitField0 = bitField0;
      if (((fromBitField0 & 0x00000001) != 0)) {
        result.name_ = name_;
      }
      if (((fromBitField0 & 0x00000002) != 0)) {
        result.fullResource_ = fullResource_;
      }
    }

    @java.lang.Override
    public Builder mergeFrom(com.google.protobuf.Message other) {
      if (other instanceof TableDataProfile) {
        return mergeFrom((TableDataProfile) other);
      } else {
        super.mergeFrom(other);
        return this;
      }
    }

    public Builder mergeFrom(TableDataProfile other) {
      if (other == TableDataProfile.getDefaultInstance()) {
        return this;
      }
      if (!other.getName().isEmpty()) {
        name_ = other.name_;
        bitField0 |= 0x00000001;
        onChanged();
      }
      if (!other.getFullResource().isEmpty()) {
        fullResource_ = other.fullResource_;
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
            case 26:
              {
                fullResource_ = input.readStringRequireUtf8();
                bitField0 |= 0x00000002;
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
     * The resource name of the table.
     * https://cloud.google.com/apis/design/resource_names#full_resource_name
     * </pre>
     *
     * <code>string full_resource = 3;</code>
     *
     * @return The fullResource.
     */
    public java.lang.String getFullResource() {
      java.lang.Object ref = fullResource_;
      if (!(ref instanceof java.lang.String)) {
        com.google.protobuf.ByteString bs = (com.google.protobuf.ByteString) ref;
        java.lang.String s = bs.toStringUtf8();
        fullResource_ = s;
        return s;
      } else {
        return (java.lang.String) ref;
      }
    }

    /**
     *
     *
     * <pre>
     * The resource name of the table.
     * https://cloud.google.com/apis/design/resource_names#full_resource_name
     * </pre>
     *
     * <code>string full_resource = 3;</code>
     *
     * @param value The fullResource to set.
     * @return This builder for chaining.
     */
    public Builder setFullResource(java.lang.String value) {
      if (value == null) {
        throw new NullPointerException();
      }
      fullResource_ = value;
      bitField0 |= 0x00000002;
      onChanged();
      return this;
    }

    /**
     *
     *
     * <pre>
     * The resource name of the table.
     * https://cloud.google.com/apis/design/resource_names#full_resource_name
     * </pre>
     *
     * <code>string full_resource = 3;</code>
     *
     * @return The bytes for fullResource.
     */
    public com.google.protobuf.ByteString getFullResourceBytes() {
      java.lang.Object ref = fullResource_;
      if (ref instanceof String) {
        com.google.protobuf.ByteString b =
            com.google.protobuf.ByteString.copyFromUtf8((java.lang.String) ref);
        fullResource_ = b;
        return b;
      } else {
        return (com.google.protobuf.ByteString) ref;
      }
    }

    /**
     *
     *
     * <pre>
     * The resource name of the table.
     * https://cloud.google.com/apis/design/resource_names#full_resource_name
     * </pre>
     *
     * <code>string full_resource = 3;</code>
     *
     * @param value The bytes for fullResource to set.
     * @return This builder for chaining.
     */
    public Builder setFullResourceBytes(com.google.protobuf.ByteString value) {
      if (value == null) {
        throw new NullPointerException();
      }
      checkByteStringIsUtf8(value);
      fullResource_ = value;
      bitField0 |= 0x00000002;
      onChanged();
      return this;
    }

    /**
     *
     *
     * <pre>
     * The resource name of the table.
     * https://cloud.google.com/apis/design/resource_names#full_resource_name
     * </pre>
     *
     * <code>string full_resource = 3;</code>
     *
     * @return This builder for chaining.
     */
    public Builder clearFullResource() {
      fullResource_ = getDefaultInstance().getFullResource();
      bitField0 = (bitField0 & ~0x00000002);
      onChanged();
      return this;
    }

    // @@protoc_insertion_point(builder_scope:com.google.internal.spma.annotations.entities.dlp.TableDataProfile)
  }
}
