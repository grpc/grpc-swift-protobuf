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

  var verbose: Bool
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
    verbose: false,
    dryRun: false
  )
}

extension CommandConfig {
  static func helpRequested(
    argumentExtractor: inout ArgumentExtractor
  ) -> Bool {
    let help = argumentExtractor.extractFlag(named: OptionsAndFlags.help.rawValue)
    return help != 0
  }

  static func parse(
    argumentExtractor argExtractor: inout ArgumentExtractor,
    pluginWorkDirectory: URL
  ) throws -> (CommandConfig, [String]) {
    var config = CommandConfig.defaults

    for flag in OptionsAndFlags.allCases {
      switch flag {
      case .accessLevel:
        let accessLevel = argExtractor.extractOption(named: flag.rawValue)
        if let value = extractSingleValue(flag, values: accessLevel) {
          if let accessLevel = GenerationConfig.AccessLevel(rawValue: value) {
            config.common.accessLevel = accessLevel
          } else {
            Diagnostics.error("Unknown access level '--\(flag.rawValue)' \(value)")
          }
        }

      case .servers, .noServers:
        if flag == .noServers { continue }  // only process this once
        let servers = argExtractor.extractFlag(named: OptionsAndFlags.servers.rawValue)
        let noServers = argExtractor.extractFlag(named: OptionsAndFlags.noServers.rawValue)
        if noServers > servers {
          config.common.servers = false
        }

      case .clients, .noClients:
        if flag == .noClients { continue }  // only process this once
        let clients = argExtractor.extractFlag(named: OptionsAndFlags.clients.rawValue)
        let noClients = argExtractor.extractFlag(named: OptionsAndFlags.noClients.rawValue)
        if noClients > clients {
          config.common.clients = false
        }

      case .messages, .noMessages:
        if flag == .noMessages { continue }  // only process this once
        let messages = argExtractor.extractFlag(named: OptionsAndFlags.messages.rawValue)
        let noMessages = argExtractor.extractFlag(named: OptionsAndFlags.noMessages.rawValue)
        if noMessages > messages {
          config.common.messages = false
        }

      case .fileNaming:
        let fileNaming = argExtractor.extractOption(named: flag.rawValue)
        if let value = extractSingleValue(flag, values: fileNaming) {
          if let fileNaming = GenerationConfig.FileNaming(rawValue: value) {
            config.common.fileNaming = fileNaming
          } else {
            Diagnostics.error("Unknown file naming strategy '--\(flag.rawValue)' \(value)")
          }
        }

      case .accessLevelOnImports:
        let accessLevelOnImports = argExtractor.extractOption(named: flag.rawValue)
        if let value = extractSingleValue(flag, values: accessLevelOnImports) {
          guard let accessLevelOnImports = Bool(value) else {
            throw CommandPluginError.invalidArgumentValue(name: flag.rawValue, value: value)
          }
          config.common.accessLevelOnImports = accessLevelOnImports
        }

      case .importPath:
        config.common.importPaths = argExtractor.extractOption(named: flag.rawValue)

      case .protocPath:
        let protocPath = argExtractor.extractOption(named: flag.rawValue)
        config.common.protocPath = extractSingleValue(flag, values: protocPath)

      case .output:
        let output = argExtractor.extractOption(named: flag.rawValue)
        config.common.outputPath =
          extractSingleValue(flag, values: output) ?? pluginWorkDirectory.absoluteStringNoScheme

      case .verbose:
        let verbose = argExtractor.extractFlag(named: flag.rawValue)
        config.verbose = verbose != 0

      case .dryRun:
        let dryRun = argExtractor.extractFlag(named: flag.rawValue)
        config.dryRun = dryRun != 0

      case .help:
        ()  // handled elsewhere
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

func extractSingleValue(_ flag: OptionsAndFlags, values: [String]) -> String? {
  if values.count > 1 {
    Stderr.print(
      "Warning: '--\(flag.rawValue)' was unexpectedly repeated, the first value will be used."
    )
  }
  return values.first
}

/// All valid input options/flags
enum OptionsAndFlags: String, CaseIterable {
  case servers
  case noServers = "no-servers"
  case clients
  case noClients = "no-clients"
  case messages
  case noMessages = "no-messages"
  case fileNaming = "file-naming"
  case accessLevel = "access-level"
  case accessLevelOnImports = "access-level-on-imports"
  case importPath = "import-path"
  case protocPath = "protoc-path"
  case output
  case verbose
  case dryRun = "dry-run"

  case help
}

extension OptionsAndFlags {
  func usageDescription() -> String {
    switch self {
    case .servers:
      return "Indicate that server code is to be generated. Generated by default."
    case .noServers:
      return "Indicate that server code is not to be generated. Generated by default."
    case .clients:
      return "Indicate that client code is to be generated. Generated by default."
    case .noClients:
      return "Indicate that client code is not to be generated. Generated by default."
    case .messages:
      return "Indicate that message code is to be generated. Generated by default."
    case .noMessages:
      return "Indicate that message code is not to be generated. Generated by default."
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
      return "The path to the protoc binary."
    case .dryRun:
      return "Print but do not execute the protoc commands."
    case .output:
      return "The path into which the generated source files are created."
    case .verbose:
      return "Emit verbose output."
    case .help:
      return "Print this help."
    }
  }

  static func printHelp(requested: Bool) {
    let printMessage: (String) -> Void
    if requested {
      printMessage = { message in print(message) }
    } else {
      printMessage = Stderr.print
    }

    printMessage("Usage: swift package generate-grpc-code-from-protos [flags] [input files]")
    printMessage("")
    printMessage("Flags:")
    printMessage("")

    let spacing = 3
    let maxLength =
      (OptionsAndFlags.allCases.map(\.rawValue).max(by: { $0.count < $1.count })?.count ?? 0)
      + spacing
    for flag in OptionsAndFlags.allCases {
      printMessage(
        "  --\(flag.rawValue.padding(toLength: maxLength, withPad: " ", startingAt: 0))\(flag.usageDescription())"
      )
    }
  }
}
