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
  using config: GenerationConfig,
  tool findTool: (String) throws -> PackagePlugin.PluginContext.Tool
) throws -> URL {
  if let configuredProtocPath = config.protocPath {
    return URL(fileURLWithPath: configuredProtocPath)
  } else if let environmentPath = ProcessInfo.processInfo.environment["PROTOC_PATH"] {
    // The user set the env variable, so let's take that
    return URL(fileURLWithPath: environmentPath)
  } else {
    // The user didn't set anything so let's try see if Swift Package Manager can find a binary for us
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
  config: GenerationConfig,
  using fileNaming: GenerationConfig.FileNaming?,
  inputFiles: [URL],
  protoDirectoryPaths: [URL],
  protocGenSwiftPath: URL,
  outputDirectory: URL
) -> [String] {
  var protocArgs = [
    "--plugin=protoc-gen-swift=\(protocGenSwiftPath.relativePath)",
    "--swift_out=\(outputDirectory.relativePath)",
  ]

  for path in config.importPaths {
    protocArgs.append("--proto_path")
    protocArgs.append("\(path)")
  }

  protocArgs.append("--swift_opt=Visibility=\(config.visibility.rawValue)")
  protocArgs.append("--swift_opt=FileNaming=\(config.fileNaming.rawValue)")
  protocArgs.append("--swift_opt=UseAccessLevelOnImports=\(config.useAccessLevelOnImports)")
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
  config: GenerationConfig,
  using fileNaming: GenerationConfig.FileNaming?,
  inputFiles: [URL],
  protoDirectoryPaths: [URL],
  protocGenGRPCSwiftPath: URL,
  outputDirectory: URL
) -> [String] {
  var protocArgs = [
    "--plugin=protoc-gen-grpc-swift=\(protocGenGRPCSwiftPath.relativePath)",
    "--grpc-swift_out=\(outputDirectory.relativePath)",
  ]

  for path in config.importPaths {
    protocArgs.append("--proto_path")
    protocArgs.append("\(path)")
  }

  protocArgs.append("--grpc-swift_opt=Visibility=\(config.visibility.rawValue.capitalized)")
  protocArgs.append("--grpc-swift_opt=Server=\(config.server)")
  protocArgs.append("--grpc-swift_opt=Client=\(config.client)")
  protocArgs.append("--grpc-swift_opt=FileNaming=\(config.fileNaming.rawValue)")
  protocArgs.append("--grpc-swift_opt=UseAccessLevelOnImports=\(config.useAccessLevelOnImports)")
  protocArgs.append(contentsOf: protoDirectoryPaths.map { "--proto_path=\($0.relativePath)" })
  protocArgs.append(contentsOf: inputFiles.map { $0.relativePath })

  return protocArgs
}
