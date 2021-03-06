// Generated by the protocol buffer compiler.  DO NOT EDIT!
// source: dlp.proto

package com.google.cloud.pso.bq_pii_classifier.entities.dlp;

/**
 * <pre>
 * A task to execute when a data profile has been generated.
 * </pre>
 *
 * Protobuf type {@code com.google.cloud.pso.bq_pii_classifier.entities.dlp.DataProfileAction}
 */
public final class DataProfileAction extends
    com.google.protobuf.GeneratedMessageV3 implements
    // @@protoc_insertion_point(message_implements:com.google.cloud.pso.bq_pii_classifier.entities.dlp.DataProfileAction)
    DataProfileActionOrBuilder {
private static final long serialVersionUID = 0L;
  // Use DataProfileAction.newBuilder() to construct.
  private DataProfileAction(com.google.protobuf.GeneratedMessageV3.Builder<?> builder) {
    super(builder);
  }
  private DataProfileAction() {
  }

  @java.lang.Override
  @SuppressWarnings({"unused"})
  protected java.lang.Object newInstance(
      UnusedPrivateParameter unused) {
    return new DataProfileAction();
  }

  @java.lang.Override
  public final com.google.protobuf.UnknownFieldSet
  getUnknownFields() {
    return this.unknownFields;
  }
  private DataProfileAction(
      com.google.protobuf.CodedInputStream input,
      com.google.protobuf.ExtensionRegistryLite extensionRegistry)
      throws com.google.protobuf.InvalidProtocolBufferException {
    this();
    if (extensionRegistry == null) {
      throw new java.lang.NullPointerException();
    }
    com.google.protobuf.UnknownFieldSet.Builder unknownFields =
        com.google.protobuf.UnknownFieldSet.newBuilder();
    try {
      boolean done = false;
      while (!done) {
        int tag = input.readTag();
        switch (tag) {
          case 0:
            done = true;
            break;
          default: {
            if (!parseUnknownField(
                input, unknownFields, extensionRegistry, tag)) {
              done = true;
            }
            break;
          }
        }
      }
    } catch (com.google.protobuf.InvalidProtocolBufferException e) {
      throw e.setUnfinishedMessage(this);
    } catch (java.io.IOException e) {
      throw new com.google.protobuf.InvalidProtocolBufferException(
          e).setUnfinishedMessage(this);
    } finally {
      this.unknownFields = unknownFields.build();
      makeExtensionsImmutable();
    }
  }
  public static final com.google.protobuf.Descriptors.Descriptor
      getDescriptor() {
    return com.google.cloud.pso.bq_pii_classifier.entities.dlp.Dlp.internal_static_com_google_cloud_pso_bq_pii_classifier_entities_dlp_DataProfileAction_descriptor;
  }

  @java.lang.Override
  protected com.google.protobuf.GeneratedMessageV3.FieldAccessorTable
      internalGetFieldAccessorTable() {
    return com.google.cloud.pso.bq_pii_classifier.entities.dlp.Dlp.internal_static_com_google_cloud_pso_bq_pii_classifier_entities_dlp_DataProfileAction_fieldAccessorTable
        .ensureFieldAccessorsInitialized(
            com.google.cloud.pso.bq_pii_classifier.entities.dlp.DataProfileAction.class, com.google.cloud.pso.bq_pii_classifier.entities.dlp.DataProfileAction.Builder.class);
  }

  /**
   * <pre>
   * Types of event that can trigger an action.
   * </pre>
   *
   * Protobuf enum {@code com.google.cloud.pso.bq_pii_classifier.entities.dlp.DataProfileAction.EventType}
   */
  public enum EventType
      implements com.google.protobuf.ProtocolMessageEnum {
    /**
     * <pre>
     * Unused.
     * </pre>
     *
     * <code>EVENT_TYPE_UNSPECIFIED = 0;</code>
     */
    EVENT_TYPE_UNSPECIFIED(0),
    /**
     * <pre>
     * New profile (not a re-profile).
     * </pre>
     *
     * <code>NEW_PROFILE = 1;</code>
     */
    NEW_PROFILE(1),
    /**
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
     * <pre>
     * Table data risk score or sensitivity score increased.
     * </pre>
     *
     * <code>SCORE_INCREASED = 3;</code>
     */
    SCORE_INCREASED(3),
    /**
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
     * <pre>
     * Unused.
     * </pre>
     *
     * <code>EVENT_TYPE_UNSPECIFIED = 0;</code>
     */
    public static final int EVENT_TYPE_UNSPECIFIED_VALUE = 0;
    /**
     * <pre>
     * New profile (not a re-profile).
     * </pre>
     *
     * <code>NEW_PROFILE = 1;</code>
     */
    public static final int NEW_PROFILE_VALUE = 1;
    /**
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
     * <pre>
     * Table data risk score or sensitivity score increased.
     * </pre>
     *
     * <code>SCORE_INCREASED = 3;</code>
     */
    public static final int SCORE_INCREASED_VALUE = 3;
    /**
     * <pre>
     * A user (non-internal) error occurred.
     * </pre>
     *
     * <code>ERROR_CHANGED = 4;</code>
     */
    public static final int ERROR_CHANGED_VALUE = 4;


    public final int getNumber() {
      if (this == UNRECOGNIZED) {
        throw new java.lang.IllegalArgumentException(
            "Can't get the number of an unknown enum value.");
      }
      return value;
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
        case 0: return EVENT_TYPE_UNSPECIFIED;
        case 1: return NEW_PROFILE;
        case 2: return CHANGED_PROFILE;
        case 3: return SCORE_INCREASED;
        case 4: return ERROR_CHANGED;
        default: return null;
      }
    }

    public static com.google.protobuf.Internal.EnumLiteMap<EventType>
        internalGetValueMap() {
      return internalValueMap;
    }
    private static final com.google.protobuf.Internal.EnumLiteMap<
        EventType> internalValueMap =
          new com.google.protobuf.Internal.EnumLiteMap<EventType>() {
            public EventType findValueByNumber(int number) {
              return EventType.forNumber(number);
            }
          };

    public final com.google.protobuf.Descriptors.EnumValueDescriptor
        getValueDescriptor() {
      if (this == UNRECOGNIZED) {
        throw new java.lang.IllegalStateException(
            "Can't get the descriptor of an unrecognized enum value.");
      }
      return getDescriptor().getValues().get(ordinal());
    }
    public final com.google.protobuf.Descriptors.EnumDescriptor
        getDescriptorForType() {
      return getDescriptor();
    }
    public static final com.google.protobuf.Descriptors.EnumDescriptor
        getDescriptor() {
      return com.google.cloud.pso.bq_pii_classifier.entities.dlp.DataProfileAction.getDescriptor().getEnumTypes().get(0);
    }

    private static final EventType[] VALUES = values();

    public static EventType valueOf(
        com.google.protobuf.Descriptors.EnumValueDescriptor desc) {
      if (desc.getType() != getDescriptor()) {
        throw new java.lang.IllegalArgumentException(
          "EnumValueDescriptor is not for this type.");
      }
      if (desc.getIndex() == -1) {
        return UNRECOGNIZED;
      }
      return VALUES[desc.getIndex()];
    }

    private final int value;

    private EventType(int value) {
      this.value = value;
    }

    // @@protoc_insertion_point(enum_scope:com.google.cloud.pso.bq_pii_classifier.entities.dlp.DataProfileAction.EventType)
  }

  private byte memoizedIsInitialized = -1;
  @java.lang.Override
  public final boolean isInitialized() {
    byte isInitialized = memoizedIsInitialized;
    if (isInitialized == 1) return true;
    if (isInitialized == 0) return false;

    memoizedIsInitialized = 1;
    return true;
  }

  @java.lang.Override
  public void writeTo(com.google.protobuf.CodedOutputStream output)
                      throws java.io.IOException {
    unknownFields.writeTo(output);
  }

  @java.lang.Override
  public int getSerializedSize() {
    int size = memoizedSize;
    if (size != -1) return size;

    size = 0;
    size += unknownFields.getSerializedSize();
    memoizedSize = size;
    return size;
  }

  @java.lang.Override
  public boolean equals(final java.lang.Object obj) {
    if (obj == this) {
     return true;
    }
    if (!(obj instanceof com.google.cloud.pso.bq_pii_classifier.entities.dlp.DataProfileAction)) {
      return super.equals(obj);
    }
    com.google.cloud.pso.bq_pii_classifier.entities.dlp.DataProfileAction other = (com.google.cloud.pso.bq_pii_classifier.entities.dlp.DataProfileAction) obj;

    if (!unknownFields.equals(other.unknownFields)) return false;
    return true;
  }

  @java.lang.Override
  public int hashCode() {
    if (memoizedHashCode != 0) {
      return memoizedHashCode;
    }
    int hash = 41;
    hash = (19 * hash) + getDescriptor().hashCode();
    hash = (29 * hash) + unknownFields.hashCode();
    memoizedHashCode = hash;
    return hash;
  }

  public static com.google.cloud.pso.bq_pii_classifier.entities.dlp.DataProfileAction parseFrom(
      java.nio.ByteBuffer data)
      throws com.google.protobuf.InvalidProtocolBufferException {
    return PARSER.parseFrom(data);
  }
  public static com.google.cloud.pso.bq_pii_classifier.entities.dlp.DataProfileAction parseFrom(
      java.nio.ByteBuffer data,
      com.google.protobuf.ExtensionRegistryLite extensionRegistry)
      throws com.google.protobuf.InvalidProtocolBufferException {
    return PARSER.parseFrom(data, extensionRegistry);
  }
  public static com.google.cloud.pso.bq_pii_classifier.entities.dlp.DataProfileAction parseFrom(
      com.google.protobuf.ByteString data)
      throws com.google.protobuf.InvalidProtocolBufferException {
    return PARSER.parseFrom(data);
  }
  public static com.google.cloud.pso.bq_pii_classifier.entities.dlp.DataProfileAction parseFrom(
      com.google.protobuf.ByteString data,
      com.google.protobuf.ExtensionRegistryLite extensionRegistry)
      throws com.google.protobuf.InvalidProtocolBufferException {
    return PARSER.parseFrom(data, extensionRegistry);
  }
  public static com.google.cloud.pso.bq_pii_classifier.entities.dlp.DataProfileAction parseFrom(byte[] data)
      throws com.google.protobuf.InvalidProtocolBufferException {
    return PARSER.parseFrom(data);
  }
  public static com.google.cloud.pso.bq_pii_classifier.entities.dlp.DataProfileAction parseFrom(
      byte[] data,
      com.google.protobuf.ExtensionRegistryLite extensionRegistry)
      throws com.google.protobuf.InvalidProtocolBufferException {
    return PARSER.parseFrom(data, extensionRegistry);
  }
  public static com.google.cloud.pso.bq_pii_classifier.entities.dlp.DataProfileAction parseFrom(java.io.InputStream input)
      throws java.io.IOException {
    return com.google.protobuf.GeneratedMessageV3
        .parseWithIOException(PARSER, input);
  }
  public static com.google.cloud.pso.bq_pii_classifier.entities.dlp.DataProfileAction parseFrom(
      java.io.InputStream input,
      com.google.protobuf.ExtensionRegistryLite extensionRegistry)
      throws java.io.IOException {
    return com.google.protobuf.GeneratedMessageV3
        .parseWithIOException(PARSER, input, extensionRegistry);
  }
  public static com.google.cloud.pso.bq_pii_classifier.entities.dlp.DataProfileAction parseDelimitedFrom(java.io.InputStream input)
      throws java.io.IOException {
    return com.google.protobuf.GeneratedMessageV3
        .parseDelimitedWithIOException(PARSER, input);
  }
  public static com.google.cloud.pso.bq_pii_classifier.entities.dlp.DataProfileAction parseDelimitedFrom(
      java.io.InputStream input,
      com.google.protobuf.ExtensionRegistryLite extensionRegistry)
      throws java.io.IOException {
    return com.google.protobuf.GeneratedMessageV3
        .parseDelimitedWithIOException(PARSER, input, extensionRegistry);
  }
  public static com.google.cloud.pso.bq_pii_classifier.entities.dlp.DataProfileAction parseFrom(
      com.google.protobuf.CodedInputStream input)
      throws java.io.IOException {
    return com.google.protobuf.GeneratedMessageV3
        .parseWithIOException(PARSER, input);
  }
  public static com.google.cloud.pso.bq_pii_classifier.entities.dlp.DataProfileAction parseFrom(
      com.google.protobuf.CodedInputStream input,
      com.google.protobuf.ExtensionRegistryLite extensionRegistry)
      throws java.io.IOException {
    return com.google.protobuf.GeneratedMessageV3
        .parseWithIOException(PARSER, input, extensionRegistry);
  }

  @java.lang.Override
  public Builder newBuilderForType() { return newBuilder(); }
  public static Builder newBuilder() {
    return DEFAULT_INSTANCE.toBuilder();
  }
  public static Builder newBuilder(com.google.cloud.pso.bq_pii_classifier.entities.dlp.DataProfileAction prototype) {
    return DEFAULT_INSTANCE.toBuilder().mergeFrom(prototype);
  }
  @java.lang.Override
  public Builder toBuilder() {
    return this == DEFAULT_INSTANCE
        ? new Builder() : new Builder().mergeFrom(this);
  }

  @java.lang.Override
  protected Builder newBuilderForType(
      com.google.protobuf.GeneratedMessageV3.BuilderParent parent) {
    Builder builder = new Builder(parent);
    return builder;
  }
  /**
   * <pre>
   * A task to execute when a data profile has been generated.
   * </pre>
   *
   * Protobuf type {@code com.google.cloud.pso.bq_pii_classifier.entities.dlp.DataProfileAction}
   */
  public static final class Builder extends
      com.google.protobuf.GeneratedMessageV3.Builder<Builder> implements
      // @@protoc_insertion_point(builder_implements:com.google.cloud.pso.bq_pii_classifier.entities.dlp.DataProfileAction)
      com.google.cloud.pso.bq_pii_classifier.entities.dlp.DataProfileActionOrBuilder {
    public static final com.google.protobuf.Descriptors.Descriptor
        getDescriptor() {
      return com.google.cloud.pso.bq_pii_classifier.entities.dlp.Dlp.internal_static_com_google_cloud_pso_bq_pii_classifier_entities_dlp_DataProfileAction_descriptor;
    }

    @java.lang.Override
    protected com.google.protobuf.GeneratedMessageV3.FieldAccessorTable
        internalGetFieldAccessorTable() {
      return com.google.cloud.pso.bq_pii_classifier.entities.dlp.Dlp.internal_static_com_google_cloud_pso_bq_pii_classifier_entities_dlp_DataProfileAction_fieldAccessorTable
          .ensureFieldAccessorsInitialized(
              com.google.cloud.pso.bq_pii_classifier.entities.dlp.DataProfileAction.class, com.google.cloud.pso.bq_pii_classifier.entities.dlp.DataProfileAction.Builder.class);
    }

    // Construct using com.google.cloud.pso.bq_pii_classifier.entities.dlp.DataProfileAction.newBuilder()
    private Builder() {
      maybeForceBuilderInitialization();
    }

    private Builder(
        com.google.protobuf.GeneratedMessageV3.BuilderParent parent) {
      super(parent);
      maybeForceBuilderInitialization();
    }
    private void maybeForceBuilderInitialization() {
      if (com.google.protobuf.GeneratedMessageV3
              .alwaysUseFieldBuilders) {
      }
    }
    @java.lang.Override
    public Builder clear() {
      super.clear();
      return this;
    }

    @java.lang.Override
    public com.google.protobuf.Descriptors.Descriptor
        getDescriptorForType() {
      return com.google.cloud.pso.bq_pii_classifier.entities.dlp.Dlp.internal_static_com_google_cloud_pso_bq_pii_classifier_entities_dlp_DataProfileAction_descriptor;
    }

    @java.lang.Override
    public com.google.cloud.pso.bq_pii_classifier.entities.dlp.DataProfileAction getDefaultInstanceForType() {
      return com.google.cloud.pso.bq_pii_classifier.entities.dlp.DataProfileAction.getDefaultInstance();
    }

    @java.lang.Override
    public com.google.cloud.pso.bq_pii_classifier.entities.dlp.DataProfileAction build() {
      com.google.cloud.pso.bq_pii_classifier.entities.dlp.DataProfileAction result = buildPartial();
      if (!result.isInitialized()) {
        throw newUninitializedMessageException(result);
      }
      return result;
    }

    @java.lang.Override
    public com.google.cloud.pso.bq_pii_classifier.entities.dlp.DataProfileAction buildPartial() {
      com.google.cloud.pso.bq_pii_classifier.entities.dlp.DataProfileAction result = new com.google.cloud.pso.bq_pii_classifier.entities.dlp.DataProfileAction(this);
      onBuilt();
      return result;
    }

    @java.lang.Override
    public Builder clone() {
      return super.clone();
    }
    @java.lang.Override
    public Builder setField(
        com.google.protobuf.Descriptors.FieldDescriptor field,
        java.lang.Object value) {
      return super.setField(field, value);
    }
    @java.lang.Override
    public Builder clearField(
        com.google.protobuf.Descriptors.FieldDescriptor field) {
      return super.clearField(field);
    }
    @java.lang.Override
    public Builder clearOneof(
        com.google.protobuf.Descriptors.OneofDescriptor oneof) {
      return super.clearOneof(oneof);
    }
    @java.lang.Override
    public Builder setRepeatedField(
        com.google.protobuf.Descriptors.FieldDescriptor field,
        int index, java.lang.Object value) {
      return super.setRepeatedField(field, index, value);
    }
    @java.lang.Override
    public Builder addRepeatedField(
        com.google.protobuf.Descriptors.FieldDescriptor field,
        java.lang.Object value) {
      return super.addRepeatedField(field, value);
    }
    @java.lang.Override
    public Builder mergeFrom(com.google.protobuf.Message other) {
      if (other instanceof com.google.cloud.pso.bq_pii_classifier.entities.dlp.DataProfileAction) {
        return mergeFrom((com.google.cloud.pso.bq_pii_classifier.entities.dlp.DataProfileAction)other);
      } else {
        super.mergeFrom(other);
        return this;
      }
    }

    public Builder mergeFrom(com.google.cloud.pso.bq_pii_classifier.entities.dlp.DataProfileAction other) {
      if (other == com.google.cloud.pso.bq_pii_classifier.entities.dlp.DataProfileAction.getDefaultInstance()) return this;
      this.mergeUnknownFields(other.unknownFields);
      onChanged();
      return this;
    }

    @java.lang.Override
    public final boolean isInitialized() {
      return true;
    }

    @java.lang.Override
    public Builder mergeFrom(
        com.google.protobuf.CodedInputStream input,
        com.google.protobuf.ExtensionRegistryLite extensionRegistry)
        throws java.io.IOException {
      com.google.cloud.pso.bq_pii_classifier.entities.dlp.DataProfileAction parsedMessage = null;
      try {
        parsedMessage = PARSER.parsePartialFrom(input, extensionRegistry);
      } catch (com.google.protobuf.InvalidProtocolBufferException e) {
        parsedMessage = (com.google.cloud.pso.bq_pii_classifier.entities.dlp.DataProfileAction) e.getUnfinishedMessage();
        throw e.unwrapIOException();
      } finally {
        if (parsedMessage != null) {
          mergeFrom(parsedMessage);
        }
      }
      return this;
    }
    @java.lang.Override
    public final Builder setUnknownFields(
        final com.google.protobuf.UnknownFieldSet unknownFields) {
      return super.setUnknownFields(unknownFields);
    }

    @java.lang.Override
    public final Builder mergeUnknownFields(
        final com.google.protobuf.UnknownFieldSet unknownFields) {
      return super.mergeUnknownFields(unknownFields);
    }


    // @@protoc_insertion_point(builder_scope:com.google.cloud.pso.bq_pii_classifier.entities.dlp.DataProfileAction)
  }

  // @@protoc_insertion_point(class_scope:com.google.cloud.pso.bq_pii_classifier.entities.dlp.DataProfileAction)
  private static final com.google.cloud.pso.bq_pii_classifier.entities.dlp.DataProfileAction DEFAULT_INSTANCE;
  static {
    DEFAULT_INSTANCE = new com.google.cloud.pso.bq_pii_classifier.entities.dlp.DataProfileAction();
  }

  public static com.google.cloud.pso.bq_pii_classifier.entities.dlp.DataProfileAction getDefaultInstance() {
    return DEFAULT_INSTANCE;
  }

  private static final com.google.protobuf.Parser<DataProfileAction>
      PARSER = new com.google.protobuf.AbstractParser<DataProfileAction>() {
    @java.lang.Override
    public DataProfileAction parsePartialFrom(
        com.google.protobuf.CodedInputStream input,
        com.google.protobuf.ExtensionRegistryLite extensionRegistry)
        throws com.google.protobuf.InvalidProtocolBufferException {
      return new DataProfileAction(input, extensionRegistry);
    }
  };

  public static com.google.protobuf.Parser<DataProfileAction> parser() {
    return PARSER;
  }

  @java.lang.Override
  public com.google.protobuf.Parser<DataProfileAction> getParserForType() {
    return PARSER;
  }

  @java.lang.Override
  public com.google.cloud.pso.bq_pii_classifier.entities.dlp.DataProfileAction getDefaultInstanceForType() {
    return DEFAULT_INSTANCE;
  }

}

