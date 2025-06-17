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

package com.google.cloud.oss.solutions.annotations.services.set;

/** Interface for a persistent set. */
public interface PersistentSet {

  /**
   * Adds a key to the set.
   *
   * @param key The key to add.
   */
  void add(String key);

  /**
   * Checks if the set contains a key.
   *
   * @param key The key to check.
   * @return True if the set contains the key, false otherwise.
   */
  boolean contains(String key);
}
