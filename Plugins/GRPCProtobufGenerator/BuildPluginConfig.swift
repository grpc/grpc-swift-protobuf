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

import Foundation

let configFileName = "grpc-swift-proto-generator-config.json"

/// The configuration of the build plugin.
struct BuildPluginConfig: Codable {
  /// The visibility of the generated files.
  ///
  /// Defaults to `Internal`.
  var visibility: GenerationConfig.Visibility
  /// Whether server code is generated.
  ///
  /// Defaults to `true`.
  var server: Bool
  /// Whether client code is generated.
  ///
  /// Defaults to `true`.
  var client: Bool
  /// Whether message code is generated.
  ///
  /// Defaults to `true`.
  var message: Bool
  /// Whether imports should have explicit access levels.
  ///
  /// Defaults to `false`.
  var useAccessLevelOnImports: Bool

  /// Specify the directory in which to search for imports.
  ///
  /// Paths are relative to the location of the specifying config file.
  /// Build plugins only have access to files within the target's source directory.
  /// May be specified multiple times; directories will be searched in order.
  /// The target source directory is always appended
  /// to the import paths.
  var importPaths: [String]

  /// The path to the `protoc` binary.
  ///
  /// If this is not set, Swift Package Manager will try to find the tool itself.
  var protocPath: String?

  // Codable conformance with defaults
  enum CodingKeys: String, CodingKey {
    case visibility
    case server
    case client
    case message
    case useAccessLevelOnImports
    case importPaths
    case protocPath
  }

  let defaultVisibility: GenerationConfig.Visibility = .internal
  let defaultServer = true
  let defaultClient = true
  let defaultMessage = true
  let defaultUseAccessLevelOnImports = false
  let defaultImportPaths: [String] = []

  init(from decoder: any Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)

    self.visibility =
      try container.decodeIfPresent(GenerationConfig.Visibility.self, forKey: .visibility)
      ?? defaultVisibility
    self.server = try container.decodeIfPresent(Bool.self, forKey: .server) ?? defaultServer
    self.client = try container.decodeIfPresent(Bool.self, forKey: .client) ?? defaultClient
    self.message = try container.decodeIfPresent(Bool.self, forKey: .message) ?? defaultMessage
    self.useAccessLevelOnImports =
      try container.decodeIfPresent(Bool.self, forKey: .useAccessLevelOnImports)
      ?? defaultUseAccessLevelOnImports
    self.importPaths =
      try container.decodeIfPresent([String].self, forKey: .importPaths) ?? defaultImportPaths
    self.protocPath = try container.decodeIfPresent(String.self, forKey: .protocPath)
  }
}

extension GenerationConfig {
  init(configurationFile: BuildPluginConfig, configurationFilePath: URL, outputPath: URL) {
    self.visibility = configurationFile.visibility
    self.server = configurationFile.server
    self.client = configurationFile.client
    self.message = configurationFile.message
    // hard-code full-path to avoid collisions since this goes into a temporary directory anyway
    self.fileNaming = .fullPath
    self.useAccessLevelOnImports = configurationFile.useAccessLevelOnImports
    self.importPaths = []

    // Generate absolute paths for the imports relative to the config file in which they are specified
    self.importPaths = configurationFile.importPaths.map { relativePath in
      configurationFilePath.deletingLastPathComponent().relativePath + "/" + relativePath
    }
    self.protocPath = configurationFile.protocPath
    self.outputPath = outputPath.relativePath
  }
}

extension GenerationConfig.Visibility: Codable {
  init?(rawValue: String) {
    switch rawValue.lowercased() {
    case "internal":
      self = .internal
    case "public":
      self = .public
    case "package":
      self = .package
    default:
      return nil
    }
  }
}
