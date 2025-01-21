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

/// The configuration of the plugin.
struct ConfigurationFile: Codable {
  /// The visibility of the generated files.
  enum Visibility: String, Codable {
    /// The generated files should have `internal` access level.
    case `internal`
    /// The generated files should have `public` access level.
    case `public`
    /// The generated files should have `package` access level.
    case `package`
  }

  /// The visibility of the generated files.
  var visibility: Visibility?
  /// Whether server code is generated.
  var server: Bool?
  /// Whether client code is generated.
  var client: Bool?
  /// Whether message code is generated.
  var message: Bool?
  //  /// Whether reflection data is generated.
  //  var reflectionData: Bool?
  /// Path to module map .asciipb file.
  var protoPathModuleMappings: String?
  /// Whether imports should have explicit access levels.
  var useAccessLevelOnImports: Bool?

  /// Specify the directory in which to search for
  /// imports. May be specified multiple times;
  /// directories will be searched in order.
  /// The target source directory is always appended
  /// to the import paths.
  var importPaths: [String]?

  /// The path to the `protoc` binary.
  ///
  /// If this is not set, SPM will try to find the tool itself.
  var protocPath: String?
}

extension CommonConfiguration {
  init(configurationFile: ConfigurationFile) {
    if let visibility = configurationFile.visibility {
      self.visibility = .init(visibility)
    }
    self.server = configurationFile.server
    self.client = configurationFile.client
    self.protoPathModuleMappings = configurationFile.protoPathModuleMappings
    self.useAccessLevelOnImports = configurationFile.useAccessLevelOnImports
    self.importPaths = configurationFile.importPaths
    self.protocPath = configurationFile.protocPath
  }
}

extension CommonConfiguration.Visibility {
  init(_ configurationFileVisibility: ConfigurationFile.Visibility) {
    switch configurationFileVisibility {
    case .internal: self = .internal
    case .public: self = .public
    case .package: self = .package
    }
  }
}
