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

/// The config of the build plugin.
struct BuildPluginConfig: Codable {
  /// Config defining which components should be considered when generating source.
  struct Generate {
    /// Whether server code is generated.
    ///
    /// Defaults to `true`.
    var servers: Bool
    /// Whether client code is generated.
    ///
    /// Defaults to `true`.
    var clients: Bool
    /// Whether message code is generated.
    ///
    /// Defaults to `true`.
    var messages: Bool

    static let defaults = Self(
      servers: true,
      clients: true,
      messages: true
    )

    private init(servers: Bool, clients: Bool, messages: Bool) {
      self.servers = servers
      self.clients = clients
      self.messages = messages
    }
  }

  /// Config relating to the generated code itself.
  struct GeneratedSource {
    /// The visibility of the generated files.
    ///
    /// Defaults to `Internal`.
    var accessLevel: GenerationConfig.AccessLevel
    /// Whether imports should have explicit access levels.
    ///
    /// Defaults to `false`.
    var accessLevelOnImports: Bool

    static let defaults = Self(
      accessLevel: .internal,
      accessLevelOnImports: false
    )

    private init(accessLevel: GenerationConfig.AccessLevel, accessLevelOnImports: Bool) {
      self.accessLevel = accessLevel
      self.accessLevelOnImports = accessLevelOnImports
    }
  }

  /// Config relating to the protoc invocation.
  struct Protoc {
    /// Specify the directory in which to search for imports.
    ///
    /// Paths are relative to the location of the specifying config file.
    /// Build plugins only have access to files within the target's source directory.
    /// May be specified multiple times; directories will be searched in order.
    /// The target source directory is always appended
    /// to the import paths.
    var importPaths: [String]

    /// The path to the `protoc` executable binary.
    ///
    /// If this is not set, Swift Package Manager will try to find the tool itself.
    var executablePath: String?

    static let defaults = Self(
      importPaths: [],
      executablePath: nil
    )

    private init(importPaths: [String], executablePath: String?) {
      self.importPaths = importPaths
      self.executablePath = executablePath
    }
  }

  /// Config defining which components should be considered when generating source.
  var generate: Generate
  /// Config relating to the nature of the generated code.
  var generatedSource: GeneratedSource
  /// Config relating to the protoc invocation.
  var protoc: Protoc

  static let defaults = Self(
    generate: Generate.defaults,
    generatedSource: GeneratedSource.defaults,
    protoc: Protoc.defaults
  )
  private init(generate: Generate, generatedSource: GeneratedSource, protoc: Protoc) {
    self.generate = generate
    self.generatedSource = generatedSource
    self.protoc = protoc
  }

  // Codable conformance with defaults
  enum CodingKeys: String, CodingKey {
    case generate
    case generatedSource
    case protoc
  }

  init(from decoder: any Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)

    self.generate =
      try container.decodeIfPresent(Generate.self, forKey: .generate) ?? Self.defaults.generate
    self.generatedSource =
      try container.decodeIfPresent(GeneratedSource.self, forKey: .generatedSource)
      ?? Self.defaults.generatedSource
    self.protoc =
      try container.decodeIfPresent(Protoc.self, forKey: .protoc) ?? Self.defaults.protoc
  }
}

extension BuildPluginConfig.Generate: Codable {
  // Codable conformance with defaults
  enum CodingKeys: String, CodingKey {
    case servers
    case clients
    case messages
  }

  init(from decoder: any Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)

    self.servers =
      try container.decodeIfPresent(Bool.self, forKey: .servers) ?? Self.defaults.servers
    self.clients =
      try container.decodeIfPresent(Bool.self, forKey: .clients) ?? Self.defaults.clients
    self.messages =
      try container.decodeIfPresent(Bool.self, forKey: .messages) ?? Self.defaults.messages
  }
}

extension BuildPluginConfig.GeneratedSource: Codable {
  // Codable conformance with defaults
  enum CodingKeys: String, CodingKey {
    case accessLevel
    case accessLevelOnImports
  }

  init(from decoder: any Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)

    self.accessLevel =
      try container.decodeIfPresent(GenerationConfig.AccessLevel.self, forKey: .accessLevel)
      ?? Self.defaults.accessLevel
    self.accessLevelOnImports =
      try container.decodeIfPresent(Bool.self, forKey: .accessLevelOnImports)
      ?? Self.defaults.accessLevelOnImports
  }
}

extension BuildPluginConfig.Protoc: Codable {
  // Codable conformance with defaults
  enum CodingKeys: String, CodingKey {
    case importPaths
    case executablePath
  }

  init(from decoder: any Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)

    self.importPaths =
      try container.decodeIfPresent([String].self, forKey: .importPaths)
      ?? Self.defaults.importPaths
    self.executablePath = try container.decodeIfPresent(String.self, forKey: .executablePath)
  }
}

extension GenerationConfig {
  init(buildPluginConfig: BuildPluginConfig, configFilePath: URL, outputPath: URL) {
    self.server = buildPluginConfig.generate.servers
    self.client = buildPluginConfig.generate.clients
    self.message = buildPluginConfig.generate.messages
    // Use path to underscores as it ensures output files are unique (files generated from
    // "foo/bar.proto" won't collide with those generated from "bar/bar.proto" as they'll be
    // uniquely named "foo_bar.(grpc|pb).swift" and "bar_bar.(grpc|pb).swift".
    self.fileNaming = .pathToUnderscores
    self.visibility = buildPluginConfig.generatedSource.accessLevel
    self.accessLevelOnImports = buildPluginConfig.generatedSource.accessLevelOnImports
    // Generate absolute paths for the imports relative to the config file in which they are specified
    self.importPaths = buildPluginConfig.protoc.importPaths.map { relativePath in
      configFilePath.deletingLastPathComponent().absoluteStringNoScheme + "/" + relativePath
    }
    self.protocPath = buildPluginConfig.protoc.executablePath
    self.outputPath = outputPath.absoluteStringNoScheme
  }
}
