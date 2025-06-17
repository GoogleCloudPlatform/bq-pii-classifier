Java Classes in this directory are generated from the following proto. This proto is curated from
the [original full version](https://github.com/googleapis/googleapis/blob/10c88bb5c489c8ad1edb0e7f6a17cdd07147966e/google/privacy/dlp/v2/dlp.proto#L4818).

The proto file itself is not checked into the code to avoid potential pre-submit rules
about checking in generated code. 


```protobuf
// Copyright 2025 Google LLC
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

// Copy of https://github.com/googleapis/googleapis/blob/10c88bb5c489c8ad1edb0e7f6a17cdd07147966e/google/privacy/dlp/v2/dlp.proto#L4818

syntax = "proto3";

package com.google.cloud.pso.bq_pii_classifier.entities.dlp;

// enables generating a separate .java file for each generated class
option java_multiple_files = true;
// specifies in what Java package name your generated classes should live
option java_package = "com.google.cloud.pso.bq_pii_classifier.entities.dlp";

// A task to execute when a data profile has been generated.
message DataProfileAction {

  // Types of event that can trigger an action.
  enum EventType {
    // Unused.
    EVENT_TYPE_UNSPECIFIED = 0;

    // New profile (not a re-profile).
    NEW_PROFILE = 1;

    // Changed one of the following profile metrics:
    // * Table data risk score
    // * Table sensitivity score
    // * Table resource visibility
    // * Table encryption type
    // * Table predicted infoTypes
    // * Table other infoTypes
    CHANGED_PROFILE = 2;

    // Table data risk score or sensitivity score increased.
    SCORE_INCREASED = 3;

    // A user (non-internal) error occurred.
    ERROR_CHANGED = 4;
  }
}

// The profile for a scanned table.
message TableDataProfile {

  // The name of the profile.
  string name = 1;

  // The resource name of the table.
  // https://cloud.google.com/apis/design/resource_names#full_resource_name
  string full_resource = 3;
}

// The profile for a scanned FileStore.
message FileStoreDataProfile {

  // The name of the profile.
  string name = 1;

  // The path of the file store.
  string file_store_path = 6;
}

// The message that will be published to a Pub/Sub topic.
// To receive a message of protocol buffer schema type, convert the message data
// to an object of this proto class.
// https://cloud.google.com/pubsub/docs/samples/pubsub-subscribe-proto-messages
message DataProfilePubSubMessage {
  // If `DetailLevel` is `TABLE_PROFILE` this will be fully populated.
  // Otherwise, if `DetailLevel` is `RESOURCE_NAME`, then only `name` and
  // `full_resource` will be populated.
  TableDataProfile profile = 1;

  // The event that caused the Pub/Sub message to be sent.
  DataProfileAction.EventType event = 2;

  // If `DetailLevel` is `FILE_STORE_PROFILE` this will be fully populated.
  // Otherwise, if `DetailLevel` is `RESOURCE_NAME`, then only `name` and
  // `file_store_path` will be populated.
  FileStoreDataProfile file_store_profile = 3;
}
```