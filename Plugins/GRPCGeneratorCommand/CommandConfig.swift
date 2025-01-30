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
import PackagePlugin

struct CommandConfig {
  var common: GenerationConfig

  var dryRun: Bool

  static let defaults = Self(
    common: .init(
      accessLevel: .internal,
      servers: true,
      clients: true,
      messages: true,
      fileNaming: .fullPath,
      accessLevelOnImports: false,
      importPaths: [],
      outputPath: ""
    ),
    dryRun: false
  )
}

extension CommandConfig {
  static func parse(
    arguments: [String],
    pluginWorkDirectory: URL
  ) throws -> (CommandConfig, [String]) {
    var config = CommandConfig.defaults

    var argExtractor = ArgumentExtractor(arguments)

    for flag in Flag.allCases {
      switch flag {
      case .accessLevel:
        let accessLevel = argExtractor.extractOption(named: flag.rawValue)
        if let value = accessLevel.first {
          switch value.lowercased() {
          case "internal":
            config.common.accessLevel = .`internal`
          case "public":
            config.common.accessLevel = .`public`
          case "package":
            config.common.accessLevel = .`package`
          default:
            Diagnostics.error("Unknown accessLevel \(value)")
          }
        }
      case .servers:
        let servers = argExtractor.extractOption(named: flag.rawValue)
        if let value = servers.first {
          guard let servers = Bool(value) else {
            throw CommandPluginError.invalidArgumentValue(value)
          }
          config.common.servers = servers
        }
      case .clients:
        let clients = argExtractor.extractOption(named: flag.rawValue)
        if let value = clients.first {
          guard let clients = Bool(value) else {
            throw CommandPluginError.invalidArgumentValue(value)
          }
          config.common.clients = clients
        }
      case .messages:
        let messages = argExtractor.extractOption(named: flag.rawValue)
        if let value = messages.first {
          guard let messages = Bool(value) else {
            throw CommandPluginError.invalidArgumentValue(value)
          }
          config.common.messages = messages
        }
      case .fileNaming:
        let fileNaming = argExtractor.extractOption(named: flag.rawValue)
        if let value = fileNaming.first {
          switch value.lowercased() {
          case "fullPath":
            config.common.fileNaming = .fullPath
          case "pathToUnderscores":
            config.common.fileNaming = .pathToUnderscores
          case "dropPath":
            config.common.fileNaming = .dropPath
          default:
            Diagnostics.error("Unknown file naming strategy \(value)")
          }
        }
      case .accessLevelOnImports:
        let accessLevelOnImports = argExtractor.extractOption(named: flag.rawValue)
        if let value = accessLevelOnImports.first {
          guard let accessLevelOnImports = Bool(value) else {
            throw CommandPluginError.invalidArgumentValue(value)
          }
          config.common.accessLevelOnImports = accessLevelOnImports
        }
      case .importPath:
        config.common.importPaths = argExtractor.extractOption(named: flag.rawValue)
      case .protocPath:
        let protocPath = argExtractor.extractOption(named: flag.rawValue)
        config.common.protocPath = protocPath.first
      case .output:
        let output = argExtractor.extractOption(named: flag.rawValue)
        config.common.outputPath = output.first ?? pluginWorkDirectory.absoluteStringNoScheme
      case .dryRun:
        let dryRun = argExtractor.extractFlag(named: flag.rawValue)
        config.dryRun = dryRun != 0
      case .help:
        let help = argExtractor.extractFlag(named: flag.rawValue)
        if help != 0 {
          throw CommandPluginError.helpRequested
        }
      }
    }

    if argExtractor.remainingArguments.isEmpty {
      throw CommandPluginError.missingInputFile
    }

    for argument in argExtractor.remainingArguments {
      if argument.hasPrefix("--") {
        throw CommandPluginError.unknownOption(argument)
      }
    }

    return (config, argExtractor.remainingArguments)
  }
}

/// All valid input options/flags
enum Flag: CaseIterable, RawRepresentable {
  typealias RawValue = String

  case servers
  case clients
  case messages
  case fileNaming
  case accessLevel
  case accessLevelOnImports
  case importPath
  case protocPath
  case output
  case dryRun

  case help

  init?(rawValue: String) {
    switch rawValue {
    case "servers":
      self = .servers
    case "clients":
      self = .clients
    case "messages":
      self = .messages
    case "file-naming":
      self = .fileNaming
    case "access-level":
      self = .accessLevel
    case "use-access-level-on-imports":
      self = .accessLevelOnImports
    case "import-path":
      self = .importPath
    case "protoc-path":
      self = .protocPath
    case "output":
      self = .output
    case "dry-run":
      self = .dryRun
    case "help":
      self = .help
    default:
      return nil
    }
    return nil
  }

  var rawValue: String {
    switch self {
    case .servers:
      "servers"
    case .clients:
      "clients"
    case .messages:
      "messages"
    case .fileNaming:
      "file-naming"
    case .accessLevel:
      "access-level"
    case .accessLevelOnImports:
      "access-level-on-imports"
    case .importPath:
      "import-path"
    case .protocPath:
      "protoc-path"
    case .output:
      "output"
    case .dryRun:
      "dry-run"
    case .help:
      "help"
    }
  }
}

extension Flag {
  func usageDescription() -> String {
    switch self {
    case .servers:
      return "Whether server code is generated. Defaults to true."
    case .clients:
      return "Whether client code is generated. Defaults to true."
    case .messages:
      return "Whether message code is generated. Defaults to true."
    case .fileNaming:
      return
        "The naming scheme for output files [fullPath/pathToUnderscores/dropPath]. Defaults to fullPath."
    case .accessLevel:
      return
        "The access level of the generated source [internal/public/package]. Defaults to internal."
    case .accessLevelOnImports:
      return "Whether imports should have explicit access levels. Defaults to false."
    case .importPath:
      return "The directory in which to search for imports."
    case .protocPath:
      return "The path to the `protoc` binary."
    case .dryRun:
      return "Print but do not execute the protoc commands."
    case .output:
      return "The path into which the generated source files are created."
    case .help:
      return "Print this help."
    }
  }

  static func printHelp() {
    print("Usage: swift package generate-grpc-code-from-protos [flags] [input files]")
    print("")
    print("Flags:")
    print("")

    let spacing = 3
    let maxLength =
      (Flag.allCases.map(\.rawValue).max(by: { $0.count < $1.count })?.count ?? 0) + spacing
    for flag in Flag.allCases {
      print(
        "  --\(flag.rawValue.padding(toLength: maxLength, withPad: " ", startingAt: 0))\(flag.usageDescription())"
      )
    }
  }
}
