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
  static var helpText: String {
    """
    USAGE: swift package generate-grpc-code-from-protos [[<options> [--]] <inputs> ...

    ARGUMENTS:
      <inputs>                    The '.proto' files or directories containing them.

    OPTIONS:
      --servers/--no-servers      Generate server code (default: --servers)
      --clients/--no-clients      Generate client code (default: --clients)
      --messages/--no-messages    Generate message code (default: --messages)
      --access-level <access>     Access level of generated code (internal/public/package)
                                  (default: internal)
      --access-level-on-imports   Whether imports have explicit access levels
      --protoc-path <path>        Path to the protoc binary
      --import-path <path>        Directory to search for imports, may be specified
                                  multiple times. If none are specified the current
                                  working directory is used.
      --file-naming <naming>      The naming scheme for generated files
                                  (fullPath/pathToUnderscores/dropPath)
                                  (default: fullPath).
      --output-path <path>        Directory to generate files into
      --verbose                   Emit verbose output
      --dry-run                   Print but don't execute the protoc commands
      --help                      Print this help

    EXAMPLES:

      swift package generate-grpc-code-from-protos service.proto
        Generates servers, clients, and messages from 'service.proto' into
        the current working directory.

      swift package generate-grpc-code-from-protos --no-clients --no-messages -- service1.proto service2.proto
        Generate only servers from service1.proto and service2.proto into the
        current working directory.

      swift package generate-grpc-code-from-protos --output-path Generated --access-level public -- Protos
        Generate server, clients, and messages from all .proto files contained
        within the 'Protos' directory into the 'Generated' directory at the
        public access level.

      swift package --allow-writing-to-package-directory generate-grpc-code-from-protos --output-path Sources/Generated -- service.proto
        Generates code from service.proto into the Sources/Generated directory
        within a Swift Package without asking for permission to do so.

    PERMISSIONS:
      Swift Package Manager command plugins require permission to create files.
      You'll be prompted to give generate-grpc-code-from-protos permission
      when running it.

      You can grant permissions by specifying --allow-writing-to-package-directory
      or --allow-writing-to-directory to the swift package command.

      See swift package plugin --help for more info.
    """
  }

  static func printHelp(requested: Bool) {
    if requested {
      print(Self.helpText)
    } else {
      Stderr.print(Self.helpText)
    }
  }
}
