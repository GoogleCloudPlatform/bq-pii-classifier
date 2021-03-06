// Generated by the protocol buffer compiler.  DO NOT EDIT!
// source: dlp.proto

package com.google.cloud.pso.bq_pii_classifier.entities.dlp;

public interface DataProfilePubSubMessageOrBuilder extends
    // @@protoc_insertion_point(interface_extends:com.google.cloud.pso.bq_pii_classifier.entities.dlp.DataProfilePubSubMessage)
    com.google.protobuf.MessageOrBuilder {

  /**
   * <pre>
   * If `DetailLevel` is `TABLE_PROFILE` this will be fully populated.
   * Otherwise, if `DetailLevel` is `RESOURCE_NAME`, then only `name` and
   * `full_resource` will be populated.
   * </pre>
   *
   * <code>.com.google.cloud.pso.bq_pii_classifier.entities.dlp.TableDataProfile profile = 1;</code>
   * @return Whether the profile field is set.
   */
  boolean hasProfile();
  /**
   * <pre>
   * If `DetailLevel` is `TABLE_PROFILE` this will be fully populated.
   * Otherwise, if `DetailLevel` is `RESOURCE_NAME`, then only `name` and
   * `full_resource` will be populated.
   * </pre>
   *
   * <code>.com.google.cloud.pso.bq_pii_classifier.entities.dlp.TableDataProfile profile = 1;</code>
   * @return The profile.
   */
  com.google.cloud.pso.bq_pii_classifier.entities.dlp.TableDataProfile getProfile();
  /**
   * <pre>
   * If `DetailLevel` is `TABLE_PROFILE` this will be fully populated.
   * Otherwise, if `DetailLevel` is `RESOURCE_NAME`, then only `name` and
   * `full_resource` will be populated.
   * </pre>
   *
   * <code>.com.google.cloud.pso.bq_pii_classifier.entities.dlp.TableDataProfile profile = 1;</code>
   */
  com.google.cloud.pso.bq_pii_classifier.entities.dlp.TableDataProfileOrBuilder getProfileOrBuilder();

  /**
   * <pre>
   * The event that caused the Pub/Sub message to be sent.
   * </pre>
   *
   * <code>.com.google.cloud.pso.bq_pii_classifier.entities.dlp.DataProfileAction.EventType event = 2;</code>
   * @return The enum numeric value on the wire for event.
   */
  int getEventValue();
  /**
   * <pre>
   * The event that caused the Pub/Sub message to be sent.
   * </pre>
   *
   * <code>.com.google.cloud.pso.bq_pii_classifier.entities.dlp.DataProfileAction.EventType event = 2;</code>
   * @return The event.
   */
  com.google.cloud.pso.bq_pii_classifier.entities.dlp.DataProfileAction.EventType getEvent();
}
