/*
 * Copyright 2024, gRPC Authors All rights reserved.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

internal enum Version {
  /// The major version.
  internal static let major = 1

  /// The minor version.
  internal static let minor = 0

  /// The patch version.
  internal static let patch = 0

  /// Any additional label.
  internal static let label = "development"

  /// The version string.
  internal static var versionString: String {
    let version = "\(Self.major).\(Self.minor).\(Self.patch)"
    if Self.label.isEmpty {
      return version
    } else {
      return version + "-" + Self.label
    }
  }
}
