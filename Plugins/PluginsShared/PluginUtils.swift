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

/// Derive the path to the instance of `protoc` to be used.
/// - Parameters:
///   - config: The supplied configuration. If no path is supplied then one is discovered using the `PROTOC_PATH` environment variable or the `findTool`.
///   - findTool: The context-supplied tool which is used to attempt to discover the path to a `protoc` binary.
/// - Returns: The path to the instance of `protoc` to be used.
func deriveProtocPath(
  using config: CommonConfiguration,
  tool findTool: (String) throws -> PackagePlugin.PluginContext.Tool
) throws -> URL {
  if let configuredProtocPath = config.protocPath {
    return URL(fileURLWithPath: configuredProtocPath)
  } else if let environmentPath = ProcessInfo.processInfo.environment["PROTOC_PATH"] {
    // The user set the env variable, so let's take that
    return URL(fileURLWithPath: environmentPath)
  } else {
    // The user didn't set anything so let's try see if SPM can find a binary for us
    return try findTool("protoc").url
  }
}

/// Construct the arguments to be passed to `protoc` when invoking the `proto-gen-swift` `protoc` plugin.
/// - Parameters:
///   - config: The configuration for this operation.
///   - fileNaming: The file naming scheme to be used.
///   - inputFiles: The input `.proto` files.
///   - protoDirectoryPaths: The directories in which `protoc` will search for imports.
///   - protocGenSwiftPath: The path to the `proto-gen-swift` `protoc` plugin.
///   - outputDirectory: The directory in which generated source files are created.
/// - Returns: The constructed arguments to be passed to `protoc` when invoking the `proto-gen-swift` `protoc` plugin.
func constructProtocGenSwiftArguments(
  config: CommonConfiguration,
  using fileNaming: CommonConfiguration.FileNaming?,
  inputFiles: [URL],
  protoDirectoryPaths: [URL],
  protocGenSwiftPath: URL,
  outputDirectory: URL
) -> [String] {
  // Construct the `protoc` arguments.
  var protocArgs = [
    "--plugin=protoc-gen-swift=\(protocGenSwiftPath.relativePath)",
    "--swift_out=\(outputDirectory.relativePath)",
  ]

  // Add the visibility if it was set
  if let visibility = config.visibility {
    protocArgs.append("--swift_opt=Visibility=\(visibility.rawValue)")
  }

  // Add the file naming
  if let fileNaming = fileNaming {
    protocArgs.append("--swift_opt=FileNaming=\(fileNaming.rawValue)")
  }

  // TODO: Don't currently support implementation only imports
  //  // Add the implementation only imports flag if it was set
  //  if let implementationOnlyImports = config.implementationOnlyImports {
  //      protocArgs.append("--swift_opt=ImplementationOnlyImports=\(implementationOnlyImports)")
  //  }

  // Add the useAccessLevelOnImports only imports flag if it was set
  if let useAccessLevelOnImports = config.useAccessLevelOnImports {
    protocArgs.append("--swift_opt=UseAccessLevelOnImports=\(useAccessLevelOnImports)")
  }

  protocArgs.append(contentsOf: protoDirectoryPaths.map { "--proto_path=\($0.relativePath)" })

  protocArgs.append(contentsOf: inputFiles.map { $0.relativePath })

  return protocArgs
}

/// Construct the arguments to be passed to `protoc` when invoking the `proto-gen-grpc-swift` `protoc` plugin.
/// - Parameters:
///   - config: The configuration for this operation.
///   - fileNaming: The file naming scheme to be used.
///   - inputFiles: The input `.proto` files.
///   - protoDirectoryPaths: The directories in which `protoc` will search for imports.
///   - protocGenGRPCSwiftPath: The path to the `proto-gen-grpc-swift` `protoc` plugin.
///   - outputDirectory: The directory in which generated source files are created.
/// - Returns: The constructed arguments to be passed to `protoc` when invoking the `proto-gen-grpc-swift` `protoc` plugin.
func constructProtocGenGRPCSwiftArguments(
  config: CommonConfiguration,
  using fileNaming: CommonConfiguration.FileNaming?,
  inputFiles: [URL],
  protoDirectoryPaths: [URL],
  protocGenGRPCSwiftPath: URL,
  outputDirectory: URL
) -> [String] {
  // Construct the `protoc` arguments.
  var protocArgs = [
    "--plugin=protoc-gen-grpc-swift=\(protocGenGRPCSwiftPath.relativePath)",
    "--grpc-swift_out=\(outputDirectory.relativePath)",
  ]

  if let importPaths = config.importPaths {
    for path in importPaths {
      protocArgs.append("-I")
      protocArgs.append("\(path)")
    }
  }

  if let visibility = config.visibility {
    protocArgs.append("--grpc-swift_opt=Visibility=\(visibility.rawValue.capitalized)")
  }

  if let generateServerCode = config.server {
    protocArgs.append("--grpc-swift_opt=Server=\(generateServerCode)")
  }

  if let generateClientCode = config.client {
    protocArgs.append("--grpc-swift_opt=Client=\(generateClientCode)")
  }

  // TODO: Don't currently support reflection data
  //  if let generateReflectionData = config.reflectionData {
  //    protocArgs.append("--grpc-swift_opt=ReflectionData=\(generateReflectionData)")
  //  }

  if let fileNaming = fileNaming {
    protocArgs.append("--grpc-swift_opt=FileNaming=\(fileNaming.rawValue)")
  }

  if let protoPathModuleMappings = config.protoPathModuleMappings {
    protocArgs.append("--grpc-swift_opt=ProtoPathModuleMappings=\(protoPathModuleMappings)")
  }

  if let useAccessLevelOnImports = config.useAccessLevelOnImports {
    protocArgs.append("--grpc-swift_opt=UseAccessLevelOnImports=\(useAccessLevelOnImports)")
  }

  protocArgs.append(contentsOf: protoDirectoryPaths.map { "--proto_path=\($0.relativePath)" })

  protocArgs.append(contentsOf: inputFiles.map { $0.relativePath })

  return protocArgs
}

/// Derive the expected output file path to match the behavior of the `proto-gen-swift` and `proto-gen-grpc-swift` `protoc` plugins.
/// - Parameters:
///   - inputFile: The input `.proto` file.
///   - fileNaming: The file naming scheme.
///   - protoDirectoryPath: The root path to the source `.proto` files used as the reference for relative path naming schemes.
///   - outputDirectory: The directory in which generated source files are created.
///   - outputExtension: The file extension to be appended to generated files in-place of `.proto`.
/// - Returns: The expected output file path.
func deriveOutputFilePath(
  for inputFile: URL,
  using fileNaming: CommonConfiguration.FileNaming,
  protoDirectoryPath: URL,
  outputDirectory: URL,
  outputExtension: String
) -> URL {
  // The name of the output file is based on the name of the input file.
  // We validated in the beginning that every file has the suffix of .proto
  // This means we can just drop the last 5 elements and append the new suffix
  let lastPathComponentRoot = inputFile.lastPathComponent.dropLast(5)
  let lastPathComponent = String(lastPathComponentRoot + outputExtension)

  // find the inputFile path relative to the proto directory
  var relativePathComponents = inputFile.deletingLastPathComponent().pathComponents
  for protoDirectoryPathComponent in protoDirectoryPath.pathComponents {
    if relativePathComponents.first == protoDirectoryPathComponent {
      relativePathComponents.removeFirst()
    } else {
      break
    }
  }

  switch fileNaming {
  case .dropPath:
    let outputFileName = lastPathComponent
    return outputDirectory.appendingPathComponent(outputFileName)
  case .fullPath:
    let outputFileComponents = relativePathComponents + [lastPathComponent]
    var outputFilePath = outputDirectory
    for outputFileComponent in outputFileComponents {
      outputFilePath.append(component: outputFileComponent)
    }
    return outputFilePath
  case .pathToUnderscores:
    let outputFileComponents = relativePathComponents + [lastPathComponent]
    let outputFileName = outputFileComponents.joined(separator: "_")
    return outputDirectory.appendingPathComponent(outputFileName)
  }
}
