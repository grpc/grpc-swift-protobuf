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

  static let parameterGroupSeparator = "--"
}

extension CommandConfig {
  static func parse(args: [String]) throws -> CommandConfig {
    var argExtractor = ArgumentExtractor(args)
    var config = CommandConfig.defaults

    for flag in OptionsAndFlags.allCases {
      switch flag {
      case .accessLevel:
        if let value = argExtractor.extractSingleOption(named: flag.rawValue) {
          if let accessLevel = GenerationConfig.AccessLevel(rawValue: value) {
            config.common.accessLevel = accessLevel
          } else {
            throw CommandPluginError.unknownAccessLevel(value)
          }
        }

      case .noServers:
        // Handled by `.servers`
        continue
      case .servers:
        let servers = argExtractor.extractFlag(named: OptionsAndFlags.servers.rawValue)
        let noServers = argExtractor.extractFlag(named: OptionsAndFlags.noServers.rawValue)
        if servers > 0 && noServers > 0 {
          throw CommandPluginError.conflictingFlags(
            OptionsAndFlags.servers.rawValue,
            OptionsAndFlags.noServers.rawValue
          )
        } else if servers > 0 {
          config.common.servers = true
        } else if noServers > 0 {
          config.common.servers = false
        }

      case .noClients:
        // Handled by `.clients`
        continue
      case .clients:
        let clients = argExtractor.extractFlag(named: OptionsAndFlags.clients.rawValue)
        let noClients = argExtractor.extractFlag(named: OptionsAndFlags.noClients.rawValue)
        if clients > 0 && noClients > 0 {
          throw CommandPluginError.conflictingFlags(
            OptionsAndFlags.clients.rawValue,
            OptionsAndFlags.noClients.rawValue
          )
        } else if clients > 0 {
          config.common.clients = true
        } else if noClients > 0 {
          config.common.clients = false
        }

      case .noMessages:
        // Handled by `.messages`
        continue
      case .messages:
        let messages = argExtractor.extractFlag(named: OptionsAndFlags.messages.rawValue)
        let noMessages = argExtractor.extractFlag(named: OptionsAndFlags.noMessages.rawValue)
        if messages > 0 && noMessages > 0 {
          throw CommandPluginError.conflictingFlags(
            OptionsAndFlags.messages.rawValue,
            OptionsAndFlags.noMessages.rawValue
          )
        } else if messages > 0 {
          config.common.messages = true
        } else if noMessages > 0 {
          config.common.messages = false
        }

      case .fileNaming:
        if let value = argExtractor.extractSingleOption(named: flag.rawValue) {
          if let fileNaming = GenerationConfig.FileNaming(rawValue: value) {
            config.common.fileNaming = fileNaming
          } else {
            throw CommandPluginError.unknownFileNamingStrategy(value)
          }
        }

      case .accessLevelOnImports:
        if argExtractor.extractFlag(named: flag.rawValue) > 0 {
          config.common.accessLevelOnImports = true
        }

      case .importPath:
        config.common.importPaths = argExtractor.extractOption(named: flag.rawValue)

      case .protocPath:
        config.common.protocPath = argExtractor.extractSingleOption(named: flag.rawValue)

      case .outputPath:
        config.common.outputPath = argExtractor.extractSingleOption(named: flag.rawValue) ?? "."

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

    if let argument = argExtractor.remainingArguments.first {
      throw CommandPluginError.unknownOption(argument)
    }

    return config
  }
}

extension ArgumentExtractor {
  mutating func extractSingleOption(named optionName: String) -> String? {
    let values = self.extractOption(named: optionName)
    if values.count > 1 {
      Diagnostics.warning(
        "'--\(optionName)' was unexpectedly repeated, the first value will be used."
      )
    }
    return values.first
  }
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
  case outputPath = "output-path"
  case verbose
  case dryRun = "dry-run"

  case help
}

extension OptionsAndFlags {
  func usageDescription() -> String {
    switch self {
    case .servers:
      return "Generate server code. Generated by default."
    case .noServers:
      return "Do not generate server code. Generated by default."
    case .clients:
      return "Generate client code. Generated by default."
    case .noClients:
      return "Do not generate client code. Generated by default."
    case .messages:
      return "Generate message code. Generated by default."
    case .noMessages:
      return "Do not generate message code. Generated by default."
    case .fileNaming:
      return
        "The naming scheme for output files [fullPath/pathToUnderscores/dropPath]. Defaults to fullPath."
    case .accessLevel:
      return
        "The access level of the generated source [internal/public/package]. Defaults to internal."
    case .accessLevelOnImports:
      return "Whether imports should have explicit access levels. Defaults to false."
    case .importPath:
      return
        "The directory in which to search for imports. May be specified multiple times. If none are specified the current working directory is used."
    case .protocPath:
      return "The path to the protoc binary."
    case .dryRun:
      return "Print but do not execute the protoc commands."
    case .outputPath:
      return "The directory into which the generated source files are created."
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

    printMessage(
      "Usage: swift package generate-grpc-code-from-protos [flags] [\(CommandConfig.parameterGroupSeparator)] [input files]"
    )
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
