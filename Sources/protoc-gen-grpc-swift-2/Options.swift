/*
 * Copyright 2017, gRPC Authors All rights reserved.
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

import GRPCCodeGen
import GRPCProtobufCodeGen
import SwiftProtobufPluginLibrary

enum GenerationError: Error, CustomStringConvertible {
  /// Raised when parsing the parameter string and found an unknown key
  case unknownParameter(name: String)
  /// Raised when a parameter was giving an invalid value
  case invalidParameterValue(name: String, value: String)
  /// Raised to wrap another error but provide a context message.
  case wrappedError(message: String, error: any Error)
  /// The parameter isn't supported.
  case unsupportedParameter(name: String, message: String)

  var description: String {
    switch self {
    case let .unknownParameter(name):
      return "Unknown generation parameter '\(name)'"
    case let .invalidParameterValue(name, value):
      return "Unknown value for generation parameter '\(name)': '\(value)'"
    case let .wrappedError(message, error):
      return "\(message): \(error)"
    case let .unsupportedParameter(name, message):
      return "Unsupported parameter '\(name)': \(message)"
    }
  }
}

enum FileNaming: String {
  case fullPath = "FullPath"
  case pathToUnderscores = "PathToUnderscores"
  case dropPath = "DropPath"
}

@available(gRPCSwiftProtobuf 2.0, *)
struct GeneratorOptions {
  private(set) var protoToModuleMappings = ProtoFileToModuleMappings()
  private(set) var fileNaming = FileNaming.fullPath
  private(set) var extraModuleImports: [String] = []
  private(set) var availabilityOverrides: [(os: String, version: String)] = []

  private(set) var config: ProtobufCodeGenerator.Config = .defaults

  init(parameter: any CodeGeneratorParameter) throws {
    try self.init(pairs: parameter.parsedPairs)
  }

  init(pairs: [(key: String, value: String)]) throws {
    var moduleMapPath: String?

    for pair in pairs {
      switch pair.key {
      case "Visibility":
        if let value = GRPCCodeGen.CodeGenerator.Config.AccessLevel(protocOption: pair.value) {
          self.config.accessLevel = value
        } else {
          throw GenerationError.invalidParameterValue(name: pair.key, value: pair.value)
        }

      case "Server":
        if let value = Bool(pair.value.lowercased()) {
          self.config.generateServer = value
        } else {
          throw GenerationError.invalidParameterValue(name: pair.key, value: pair.value)
        }

      case "Client":
        if let value = Bool(pair.value.lowercased()) {
          self.config.generateClient = value
        } else {
          throw GenerationError.invalidParameterValue(name: pair.key, value: pair.value)
        }

      case "ProtoPathModuleMappings":
        if !pair.value.isEmpty {
          moduleMapPath = pair.value
        }

      case "FileNaming":
        if let value = FileNaming(rawValue: pair.value) {
          self.fileNaming = value
        } else {
          throw GenerationError.invalidParameterValue(name: pair.key, value: pair.value)
        }

      case "ExtraModuleImports":
        if !pair.value.isEmpty {
          self.extraModuleImports.append(pair.value)
        } else {
          throw GenerationError.invalidParameterValue(name: pair.key, value: pair.value)
        }

      case "GRPCModuleName":
        if !pair.value.isEmpty {
          self.config.moduleNames.grpcCore = pair.value
        } else {
          throw GenerationError.invalidParameterValue(name: pair.key, value: pair.value)
        }

      case "GRPCProtobufModuleName":
        if !pair.value.isEmpty {
          self.config.moduleNames.grpcProtobuf = pair.value
        } else {
          throw GenerationError.invalidParameterValue(name: pair.key, value: pair.value)
        }

      case "SwiftProtobufModuleName":
        if !pair.value.isEmpty {
          self.config.moduleNames.swiftProtobuf = pair.value
        } else {
          throw GenerationError.invalidParameterValue(name: pair.key, value: pair.value)
        }

      case "Availability":
        if !pair.value.isEmpty {
          let parts = pair.value.split(separator: " ", maxSplits: 1)
          if parts.count == 2 {
            self.availabilityOverrides.append((os: String(parts[0]), version: String(parts[1])))
          } else {
            throw GenerationError.invalidParameterValue(name: pair.key, value: pair.value)
          }
        } else {
          throw GenerationError.invalidParameterValue(name: pair.key, value: pair.value)
        }

      case "ReflectionData":
        throw GenerationError.unsupportedParameter(
          name: pair.key,
          message: """
            The reflection service uses descriptor sets. Refer to the protoc docs and the \
            '--descriptor_set_out' option for more information.
            """
        )

      case "UseAccessLevelOnImports":
        if let value = Bool(pair.value.lowercased()) {
          self.config.accessLevelOnImports = value
        } else {
          throw GenerationError.invalidParameterValue(name: pair.key, value: pair.value)
        }

      default:
        throw GenerationError.unknownParameter(name: pair.key)
      }
    }

    if let moduleMapPath = moduleMapPath {
      do {
        self.protoToModuleMappings = try ProtoFileToModuleMappings(
          path: moduleMapPath,
          swiftProtobufModuleName: self.config.moduleNames.swiftProtobuf
        )
      } catch let e {
        throw GenerationError.wrappedError(
          message: "Parameter 'ProtoPathModuleMappings=\(moduleMapPath)'",
          error: e
        )
      }
    } else {
      self.protoToModuleMappings = ProtoFileToModuleMappings(
        swiftProtobufModuleName: self.config.moduleNames.swiftProtobuf
      )
    }
  }

  static func parseParameter(string: String?) -> [(key: String, value: String)] {
    guard let string = string, !string.isEmpty else {
      return []
    }

    let parts = string.split(separator: ",")

    // Partitions the string into the section before the = and after the =
    let result = parts.map { string -> (key: String, value: String) in
      // Finds the equal sign and exits early if none
      guard let index = string.firstIndex(of: "=") else {
        return (String(string), "")
      }

      // Creates key/value pair and trims whitespace
      let key = string[..<index]
        .trimmingWhitespaceAndNewlines()
      let value = string[string.index(after: index)...]
        .trimmingWhitespaceAndNewlines()

      return (key: key, value: value)
    }
    return result
  }
}

@available(gRPCSwiftProtobuf 2.0, *)
extension String.SubSequence {
  func trimmingWhitespaceAndNewlines() -> String {
    let trimmedSuffix = self.drop(while: { $0.isNewline || $0.isWhitespace })
    let trimmed = trimmedSuffix.trimmingPrefix(while: { $0.isNewline || $0.isWhitespace })
    return String(trimmed)
  }
}

@available(gRPCSwiftProtobuf 2.0, *)
extension GRPCCodeGen.CodeGenerator.Config.AccessLevel {
  fileprivate init?(protocOption value: String) {
    switch value {
    case "Internal":
      self = .internal
    case "Public":
      self = .public
    case "Package":
      self = .package
    default:
      return nil
    }
  }
}
