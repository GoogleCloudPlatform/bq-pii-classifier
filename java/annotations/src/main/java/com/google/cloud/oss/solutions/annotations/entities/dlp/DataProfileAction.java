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
 * A task to execute when a data profile has been generated.
 * </pre>
 *
 * Protobuf type {@code com.google.internal.spma.annotations.entities.dlp.DataProfileAction}
 */
public final class DataProfileAction extends com.google.protobuf.GeneratedMessage
    implements
    // @@protoc_insertion_point(message_implements:com.google.internal.spma.annotations.entities.dlp.DataProfileAction)
    DataProfileActionOrBuilder {
  private static final long serialVersionUID = 0L;
  // @@protoc_insertion_point(class_scope:com.google.internal.spma.annotations.entities.dlp.DataProfileAction)
  private static final DataProfileAction DEFAULT_INSTANCE;
  private static final com.google.protobuf.Parser<DataProfileAction> PARSER =
      new com.google.protobuf.AbstractParser<DataProfileAction>() {
        @java.lang.Override
        public DataProfileAction parsePartialFrom(
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
        DataProfileAction.class.getName());
  }

  static {
    DEFAULT_INSTANCE = new DataProfileAction();
  }

  private byte memoizedIsInitialized = -1;

  // Use DataProfileAction.newBuilder() to construct.
  private DataProfileAction(com.google.protobuf.GeneratedMessage.Builder<?> builder) {
    super(builder);
  }

  private DataProfileAction() {}

  public static com.google.protobuf.Descriptors.Descriptor getDescriptor() {
    return Dlp
        .internal_static_com_google_cloud_pso_bq_pii_classifier_entities_dlp_DataProfileAction_descriptor;
  }

  public static DataProfileAction parseFrom(java.nio.ByteBuffer data)
      throws com.google.protobuf.InvalidProtocolBufferException {
    return PARSER.parseFrom(data);
  }

  public static DataProfileAction parseFrom(
      java.nio.ByteBuffer data, com.google.protobuf.ExtensionRegistryLite extensionRegistry)
      throws com.google.protobuf.InvalidProtocolBufferException {
    return PARSER.parseFrom(data, extensionRegistry);
  }

  public static DataProfileAction parseFrom(com.google.protobuf.ByteString data)
      throws com.google.protobuf.InvalidProtocolBufferException {
    return PARSER.parseFrom(data);
  }

  public static DataProfileAction parseFrom(
      com.google.protobuf.ByteString data,
      com.google.protobuf.ExtensionRegistryLite extensionRegistry)
      throws com.google.protobuf.InvalidProtocolBufferException {
    return PARSER.parseFrom(data, extensionRegistry);
  }

  public static DataProfileAction parseFrom(byte[] data)
      throws com.google.protobuf.InvalidProtocolBufferException {
    return PARSER.parseFrom(data);
  }

  public static DataProfileAction parseFrom(
      byte[] data, com.google.protobuf.ExtensionRegistryLite extensionRegistry)
      throws com.google.protobuf.InvalidProtocolBufferException {
    return PARSER.parseFrom(data, extensionRegistry);
  }

  public static DataProfileAction parseFrom(java.io.InputStream input) throws java.io.IOException {
    return com.google.protobuf.GeneratedMessage.parseWithIOException(PARSER, input);
  }

  public static DataProfileAction parseFrom(
      java.io.InputStream input, com.google.protobuf.ExtensionRegistryLite extensionRegistry)
      throws java.io.IOException {
    return com.google.protobuf.GeneratedMessage.parseWithIOException(
        PARSER, input, extensionRegistry);
  }

  public static DataProfileAction parseDelimitedFrom(java.io.InputStream input)
      throws java.io.IOException {
    return com.google.protobuf.GeneratedMessage.parseDelimitedWithIOException(PARSER, input);
  }

  public static DataProfileAction parseDelimitedFrom(
      java.io.InputStream input, com.google.protobuf.ExtensionRegistryLite extensionRegistry)
      throws java.io.IOException {
    return com.google.protobuf.GeneratedMessage.parseDelimitedWithIOException(
        PARSER, input, extensionRegistry);
  }

  public static DataProfileAction parseFrom(com.google.protobuf.CodedInputStream input)
      throws java.io.IOException {
    return com.google.protobuf.GeneratedMessage.parseWithIOException(PARSER, input);
  }

  public static DataProfileAction parseFrom(
      com.google.protobuf.CodedInputStream input,
      com.google.protobuf.ExtensionRegistryLite extensionRegistry)
      throws java.io.IOException {
    return com.google.protobuf.GeneratedMessage.parseWithIOException(
        PARSER, input, extensionRegistry);
  }

  public static Builder newBuilder() {
    return DEFAULT_INSTANCE.toBuilder();
  }

  public static Builder newBuilder(DataProfileAction prototype) {
    return DEFAULT_INSTANCE.toBuilder().mergeFrom(prototype);
  }

  public static DataProfileAction getDefaultInstance() {
    return DEFAULT_INSTANCE;
  }

  public static com.google.protobuf.Parser<DataProfileAction> parser() {
    return PARSER;
  }

  @java.lang.Override
  protected com.google.protobuf.GeneratedMessage.FieldAccessorTable
      internalGetFieldAccessorTable() {
    return Dlp
        .internal_static_com_google_cloud_pso_bq_pii_classifier_entities_dlp_DataProfileAction_fieldAccessorTable
        .ensureFieldAccessorsInitialized(DataProfileAction.class, DataProfileAction.Builder.class);
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
    getUnknownFields().writeTo(output);
  }

  @java.lang.Override
  public int getSerializedSize() {
    int size = memoizedSize;
    if (size != -1) {
      return size;
    }

    size = 0;
    size += getUnknownFields().getSerializedSize();
    memoizedSize = size;
    return size;
  }

  @java.lang.Override
  public boolean equals(final java.lang.Object obj) {
    if (obj == this) {
      return true;
    }
    if (!(obj instanceof DataProfileAction other)) {
      return super.equals(obj);
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
  public com.google.protobuf.Parser<DataProfileAction> getParserForType() {
    return PARSER;
  }

  @java.lang.Override
  public DataProfileAction getDefaultInstanceForType() {
    return DEFAULT_INSTANCE;
  }

  /**
   *
   *
   * <pre>
   * Types of event that can trigger an action.
   * </pre>
   *
   * Protobuf enum {@code
   * com.google.internal.spma.annotations.entities.dlp.DataProfileAction.EventType}
   */
  public enum EventType implements com.google.protobuf.ProtocolMessageEnum {
    /**
     *
     *
     * <pre>
     * Unused.
     * </pre>
     *
     * <code>EVENT_TYPE_UNSPECIFIED = 0;</code>
     */
    EVENT_TYPE_UNSPECIFIED(0),
    /**
     *
     *
     * <pre>
     * New profile (not a re-profile).
     * </pre>
     *
     * <code>NEW_PROFILE = 1;</code>
     */
    NEW_PROFILE(1),
    /**
     *
     *
     * <pre>
     * Changed one of the following profile metrics:
     * * Table data risk score
     * * Table sensitivity score
     * * Table resource visibility
     * * Table encryption type
     * * Table predicted infoTypes
     * * Table other infoTypes
     * </pre>
     *
     * <code>CHANGED_PROFILE = 2;</code>
     */
    CHANGED_PROFILE(2),
    /**
     *
     *
     * <pre>
     * Table data risk score or sensitivity score increased.
     * </pre>
     *
     * <code>SCORE_INCREASED = 3;</code>
     */
    SCORE_INCREASED(3),
    /**
     *
     *
     * <pre>
     * A user (non-internal) error occurred.
     * </pre>
     *
     * <code>ERROR_CHANGED = 4;</code>
     */
    ERROR_CHANGED(4),
    UNRECOGNIZED(-1),
    ;

    /**
     *
     *
     * <pre>
     * Unused.
     * </pre>
     *
     * <code>EVENT_TYPE_UNSPECIFIED = 0;</code>
     */
    public static final int EVENT_TYPE_UNSPECIFIED_VALUE = 0;

    /**
     *
     *
     * <pre>
     * New profile (not a re-profile).
     * </pre>
     *
     * <code>NEW_PROFILE = 1;</code>
     */
    public static final int NEW_PROFILE_VALUE = 1;

    /**
     *
     *
     * <pre>
     * Changed one of the following profile metrics:
     * * Table data risk score
     * * Table sensitivity score
     * * Table resource visibility
     * * Table encryption type
     * * Table predicted infoTypes
     * * Table other infoTypes
     * </pre>
     *
     * <code>CHANGED_PROFILE = 2;</code>
     */
    public static final int CHANGED_PROFILE_VALUE = 2;

    /**
     *
     *
     * <pre>
     * Table data risk score or sensitivity score increased.
     * </pre>
     *
     * <code>SCORE_INCREASED = 3;</code>
     */
    public static final int SCORE_INCREASED_VALUE = 3;

    /**
     *
     *
     * <pre>
     * A user (non-internal) error occurred.
     * </pre>
     *
     * <code>ERROR_CHANGED = 4;</code>
     */
    public static final int ERROR_CHANGED_VALUE = 4;

    private static final com.google.protobuf.Internal.EnumLiteMap<EventType> internalValueMap =
        new com.google.protobuf.Internal.EnumLiteMap<EventType>() {
          public EventType findValueByNumber(int number) {
            return EventType.forNumber(number);
          }
        };
    private static final EventType[] VALUES = values();

    static {
      com.google.protobuf.RuntimeVersion.validateProtobufGencodeVersion(
          com.google.protobuf.RuntimeVersion.RuntimeDomain.PUBLIC,
          /* major= */ 4,
          /* minor= */ 29,
          /* patch= */ 3,
          /* suffix= */ "",
          EventType.class.getName());
    }

    private final int value;

    EventType(int value) {
      this.value = value;
    }

    /**
     * @param value The numeric wire value of the corresponding enum entry.
     * @return The enum associated with the given numeric wire value.
     * @deprecated Use {@link #forNumber(int)} instead.
     */
    @java.lang.Deprecated
    public static EventType valueOf(int value) {
      return forNumber(value);
    }

    /**
     * @param value The numeric wire value of the corresponding enum entry.
     * @return The enum associated with the given numeric wire value.
     */
    public static EventType forNumber(int value) {
      switch (value) {
        case 0:
          return EVENT_TYPE_UNSPECIFIED;
        case 1:
          return NEW_PROFILE;
        case 2:
          return CHANGED_PROFILE;
        case 3:
          return SCORE_INCREASED;
        case 4:
          return ERROR_CHANGED;
        default:
          return null;
      }
    }

    public static com.google.protobuf.Internal.EnumLiteMap<EventType> internalGetValueMap() {
      return internalValueMap;
    }

    public static final com.google.protobuf.Descriptors.EnumDescriptor getDescriptor() {
      return DataProfileAction.getDescriptor().getEnumTypes().get(0);
    }

    public static EventType valueOf(com.google.protobuf.Descriptors.EnumValueDescriptor desc) {
      if (desc.getType() != getDescriptor()) {
        throw new java.lang.IllegalArgumentException("EnumValueDescriptor is not for this type.");
      }
      if (desc.getIndex() == -1) {
        return UNRECOGNIZED;
      }
      return VALUES[desc.getIndex()];
    }

    public final int getNumber() {
      if (this == UNRECOGNIZED) {
        throw new java.lang.IllegalArgumentException(
            "Can't get the number of an unknown enum value.");
      }
      return value;
    }

    public final com.google.protobuf.Descriptors.EnumValueDescriptor getValueDescriptor() {
      if (this == UNRECOGNIZED) {
        throw new java.lang.IllegalStateException(
            "Can't get the descriptor of an unrecognized enum value.");
      }
      return getDescriptor().getValues().get(ordinal());
    }

    public final com.google.protobuf.Descriptors.EnumDescriptor getDescriptorForType() {
      return getDescriptor();
    }

    // @@protoc_insertion_point(enum_scope:com.google.internal.spma.annotations.entities.dlp.DataProfileAction.EventType)
  }

  /**
   *
   *
   * <pre>
   * A task to execute when a data profile has been generated.
   * </pre>
   *
   * Protobuf type {@code com.google.internal.spma.annotations.entities.dlp.DataProfileAction}
   */
  public static final class Builder extends com.google.protobuf.GeneratedMessage.Builder<Builder>
      implements
      // @@protoc_insertion_point(builder_implements:com.google.internal.spma.annotations.entities.dlp.DataProfileAction)
      DataProfileActionOrBuilder {
    // Construct using
    // com.google.internal.spma.annotations.entities.dlp.DataProfileAction.newBuilder()
    private Builder() {}

    private Builder(com.google.protobuf.GeneratedMessage.BuilderParent parent) {
      super(parent);
    }

    public static com.google.protobuf.Descriptors.Descriptor getDescriptor() {
      return Dlp
          .internal_static_com_google_cloud_pso_bq_pii_classifier_entities_dlp_DataProfileAction_descriptor;
    }

    @java.lang.Override
    protected com.google.protobuf.GeneratedMessage.FieldAccessorTable
        internalGetFieldAccessorTable() {
      return Dlp
          .internal_static_com_google_cloud_pso_bq_pii_classifier_entities_dlp_DataProfileAction_fieldAccessorTable
          .ensureFieldAccessorsInitialized(
              DataProfileAction.class, DataProfileAction.Builder.class);
    }

    @java.lang.Override
    public Builder clear() {
      super.clear();
      return this;
    }

    @java.lang.Override
    public com.google.protobuf.Descriptors.Descriptor getDescriptorForType() {
      return Dlp
          .internal_static_com_google_cloud_pso_bq_pii_classifier_entities_dlp_DataProfileAction_descriptor;
    }

    @java.lang.Override
    public DataProfileAction getDefaultInstanceForType() {
      return DataProfileAction.getDefaultInstance();
    }

    @java.lang.Override
    public DataProfileAction build() {
      DataProfileAction result = buildPartial();
      if (!result.isInitialized()) {
        throw newUninitializedMessageException(result);
      }
      return result;
    }

    @java.lang.Override
    public DataProfileAction buildPartial() {
      DataProfileAction result = new DataProfileAction(this);
      onBuilt();
      return result;
    }

    @java.lang.Override
    public Builder mergeFrom(com.google.protobuf.Message other) {
      if (other instanceof DataProfileAction) {
        return mergeFrom((DataProfileAction) other);
      } else {
        super.mergeFrom(other);
        return this;
      }
    }

    public Builder mergeFrom(DataProfileAction other) {
      if (other == DataProfileAction.getDefaultInstance()) {
        return this;
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

    // @@protoc_insertion_point(builder_scope:com.google.internal.spma.annotations.entities.dlp.DataProfileAction)
  }
}
