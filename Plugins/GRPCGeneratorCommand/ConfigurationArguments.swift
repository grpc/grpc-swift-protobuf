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

struct CommandConfiguration {
  var common: CommonConfiguration

  var dryRun: Bool
}

extension CommandConfiguration {
  init(arguments: [String]) throws {
    self.common = CommonConfiguration()
    self.common.importPaths = []

    var dryRun: Bool?

    var arguments = arguments
    while arguments.count > 0 {
      let argument = arguments.removeFirst()
      if !argument.hasPrefix("-") {
        continue
      }

      let flag = try Flag(argument)
      guard argument.count > 0 else {
        throw PluginError.missingArgumentValue
      }
      let value = arguments.removeFirst()

      switch flag {
      case .visibility:
        switch value.lowercased() {
        case "internal":
          self.common.visibility = .`internal`
        case "public":
          self.common.visibility = .`public`
        case "package":
          self.common.visibility = .`package`
        default:
          Diagnostics.error("Unknown visibility \(value)")
        }
      case .server:
        self.common.server = .init(value)
      case .client:
        self.common.client = .init(value)
      case .message:
        self.common.message = .init(value)
      case .fileNaming:
        switch value.lowercased() {
        case "fullPath":
          self.common.fileNaming = .fullPath
        case "pathToUnderscores":
          self.common.fileNaming = .pathToUnderscores
        case "dropPath":
          self.common.fileNaming = .dropPath
        default:
          Diagnostics.error("Unknown file naming strategy \(value)")
        }
      case .protoPathModuleMappings:
        self.common.protoPathModuleMappings = value
      case .useAccessLevelOnImports:
        self.common.useAccessLevelOnImports = .init(value)
      case .importPath:
        // ! is safe because we set it to an empty array at the top of the method
        self.common.importPaths!.append(value)
      case .protocPath:
        self.common.protocPath = value
      case .output:
        self.common.outputPath = value
      case .dryRun:
        dryRun = .init(value)
      }
    }

    // defaults
    self.dryRun = dryRun ?? false
  }
}

func inputFiles(from arguments: [String]) -> [String] {
  var files: [String] = []
  var arguments = arguments
  while arguments.count > 0 {
    let argument = arguments.removeFirst()
    if argument.hasPrefix("-") {
      _ = arguments.removeFirst()  // also discard the value
      continue  // discard the flag
    }
    files.append(argument)
  }
  return files
}

extension Bool {
  private init(_ string: String) {
    switch string.lowercased() {
    case "true":
      self = true
    case "false":
      self = false
    default:
      Diagnostics.error("Unknown boolean \(string)")
      self = false
    }
  }
}

enum Flag: CaseIterable {
  case visibility
  case server
  case client
  case message
  case fileNaming
  case protoPathModuleMappings
  case useAccessLevelOnImports
  case importPath
  case protocPath
  case output

  case dryRun

  init(_ argument: String) throws {
    switch argument {
    case "--visibility":
      self = .visibility
    case "--server":
      self = .server
    case "--client":
      self = .client
    case "--message":
      self = .message
    case "--file-naming":
      self = .fileNaming
    case "--proto-path-module-mappings":
      self = .protoPathModuleMappings
    case "--use-access-level-on-imports":
      self = .useAccessLevelOnImports
    case "--import-path", "-I":
      self = .importPath
    case "--protoc-path":
      self = .protocPath
    case "--output":
      self = .output
    case "--dry-run":
      self = .dryRun
    case "--help":
      throw PluginError.helpRequested
    default:
      Diagnostics.error("Unknown flag \(argument)")
      throw PluginError.unknownOption(argument)
    }
  }
}

extension Flag {
  func usageDescription() -> String {
    switch self {
    case .visibility:
      return "--visibility                    The visibility of the generated files."
    case .server:
      return "--server                        Whether server code is generated."
    case .client:
      return "--client                        Whether client code is generated."
    case .message:
      return "--message                       Whether message code is generated."
    case .fileNaming:
      return
        "--file-naming                   The naming of output files with respect to the path of the source file."
    case .protoPathModuleMappings:
      return "--proto-path-module-mappings    Path to module map .asciipb file."
    case .useAccessLevelOnImports:
      return "--use-access-level-on-imports   Whether imports should have explicit access levels."
    case .importPath:
      return "--import-path                   The directory in which to search for imports."
    case .protocPath:
      return "--protoc-path                   The path to the `protoc` binary."
    case .dryRun:
      return "--dry-run                       Print but do not execute the protoc commands."
    case .output:
      return
        "--output                        The path into which the generated source files are created."
    }
  }

  static func printHelp() {
    print("Usage: swift package generate-grpc-code-from-protos [flags] [input files]")
    print("")
    print("Flags:")
    print("")
    for flag in Flag.allCases { print("  \(flag.usageDescription())") }
    print("")
    print("  --help                          Print this help.")
  }
}
