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

@main
struct GRPCProtobufGenerator {
  /// Build plugin code common to both invocation types: package manifest Xcode project
  func createBuildCommands(
    pluginWorkDirectory: URL,
    tool: (String) throws -> PluginContext.Tool,
    inputFiles: [URL],
    configFiles: [URL],
    targetName: String
  ) throws -> [Command] {
    let configs = try readConfigurationFiles(configFiles, pluginWorkDirectory: pluginWorkDirectory)

    let protocGenGRPCSwiftPath = try tool("protoc-gen-grpc-swift").url
    let protocGenSwiftPath = try tool("protoc-gen-swift").url

    var commands: [Command] = []
    for inputFile in inputFiles {
      guard let (configFilePath, config) = configs.findApplicableConfig(for: inputFile) else {
        throw PluginError.noConfigurationFilesFound
      }

      let protocPath = try deriveProtocPath(using: config, tool: tool)
      let protoDirectoryPath = inputFile.deletingLastPathComponent()

      // unless *explicitly* opted-out
      if config.client || config.server {
        let grpcCommand = try protocGenGRPCSwiftCommand(
          inputFile: inputFile,
          config: config,
          protoDirectoryPath: protoDirectoryPath,
          protocPath: protocPath,
          protocGenGRPCSwiftPath: protocGenGRPCSwiftPath
        )
        commands.append(grpcCommand)
      }

      // unless *explicitly* opted-out
      if config.message != false {
        let protoCommand = try protocGenSwiftCommand(
          inputFile: inputFile,
          config: config,
          protoDirectoryPath: protoDirectoryPath,
          protocPath: protocPath,
          protocGenSwiftPath: protocGenSwiftPath,
          configFilePath: configFilePath
        )
        commands.append(protoCommand)
      }
    }

    return commands
  }
}

/// Reads the configuration files at the supplied URLs into memory
/// - Parameter configurationFiles: URLs from which to load configuration
/// - Returns: A map of source URLs to loaded configuration
func readConfigurationFiles(
  _ configurationFiles: [URL],
  pluginWorkDirectory: URL
) throws -> [URL: GenerationConfig] {
  var configs: [URL: GenerationConfig] = [:]
  for configFile in configurationFiles {
    let data = try Data(contentsOf: configFile)
    let configuration = try JSONDecoder().decode(BuildPluginConfig.self, from: data)

    // the output directory mandated by the plugin system
    configs[configFile] = GenerationConfig(
      configurationFile: configuration,
      configurationFilePath: configFile,
      outputPath: pluginWorkDirectory
    )
  }
  return configs
}

extension [URL: GenerationConfig] {
  /// Finds the most precisely relevant config file for a given proto file URL.
  /// - Parameters:
  ///   - file: The path to the proto file to be matched.
  /// - Returns: The path to the most precisely relevant config file if one is found and the config itself, otherwise `nil`.
  func findApplicableConfig(for file: URL) -> (URL, GenerationConfig)? {
    let filePathComponents = file.pathComponents
    for endComponent in (0 ..< filePathComponents.count).reversed() {
      for (configFilePath, config) in self {
        if filePathComponents[..<endComponent]
          == configFilePath.pathComponents[..<(configFilePath.pathComponents.count - 1)]
        {
          return (configFilePath, config)
        }
      }
    }

    return nil
  }
}

/// Construct the command to invoke `protoc` with the `proto-gen-grpc-swift` plugin.
/// - Parameters:
///   - inputFile: The input `.proto` file.
///   - config: The configuration for this operation.
///   - protoDirectoryPath: The root path to the source `.proto` files used as the reference for relative path naming schemes.
///   - protocPath: The path to `protoc`
///   - protocGenGRPCSwiftPath: The path to `proto-gen-grpc-swift`.
/// - Returns: The command to invoke `protoc` with the `proto-gen-grpc-swift` plugin.
func protocGenGRPCSwiftCommand(
  inputFile: URL,
  config: GenerationConfig,
  protoDirectoryPath: URL,
  protocPath: URL,
  protocGenGRPCSwiftPath: URL
) throws -> PackagePlugin.Command {
  let outputPathURL = URL(fileURLWithPath: config.outputPath)

  let outputFilePath = deriveOutputFilePath(
    for: inputFile,
    protoDirectoryPath: protoDirectoryPath,
    outputDirectory: outputPathURL,
    outputExtension: "grpc.swift"
  )

  let arguments = constructProtocGenGRPCSwiftArguments(
    config: config,
    using: config.fileNaming,
    inputFiles: [inputFile],
    protoDirectoryPaths: [protoDirectoryPath],
    protocGenGRPCSwiftPath: protocGenGRPCSwiftPath,
    outputDirectory: outputPathURL
  )

  return Command.buildCommand(
    displayName: "Generating gRPC Swift files for \(inputFile.relativePath)",
    executable: protocPath,
    arguments: arguments,
    inputFiles: [inputFile, protocGenGRPCSwiftPath],
    outputFiles: [outputFilePath]
  )
}

/// Construct the command to invoke `protoc` with the `proto-gen-swift` plugin.
/// - Parameters:
///   - inputFile: The input `.proto` file.
///   - config: The configuration for this operation.
///   - protoDirectoryPath: The root path to the source `.proto` files used as the reference for relative path naming schemes.
///   - protocPath: The path to `protoc`
///   - protocGenSwiftPath: The path to `proto-gen-grpc-swift`.
///   - configFilePath: The path to the config file in use.
/// - Returns: The command to invoke `protoc` with the `proto-gen-swift` plugin.
func protocGenSwiftCommand(
  inputFile: URL,
  config: GenerationConfig,
  protoDirectoryPath: URL,
  protocPath: URL,
  protocGenSwiftPath: URL,
  configFilePath: URL
) throws -> PackagePlugin.Command {
  let outputPathURL = URL(fileURLWithPath: config.outputPath)

  let outputFilePath = deriveOutputFilePath(
    for: inputFile,
    protoDirectoryPath: protoDirectoryPath,
    outputDirectory: outputPathURL,
    outputExtension: "pb.swift"
  )

  let arguments = constructProtocGenSwiftArguments(
    config: config,
    using: config.fileNaming,
    inputFiles: [inputFile],
    protoDirectoryPaths: [protoDirectoryPath],
    protocGenSwiftPath: protocGenSwiftPath,
    outputDirectory: outputPathURL
  )

  return Command.buildCommand(
    displayName: "Generating Swift Protobuf files for \(inputFile.relativePath)",
    executable: protocPath,
    arguments: arguments,
    inputFiles: [
      inputFile,
      protocGenSwiftPath,
      configFilePath
    ],
    outputFiles: [outputFilePath]
  )
}

/// Derive the expected output file path to match the behavior of the `proto-gen-swift` and `proto-gen-grpc-swift` `protoc` plugins.
/// - Parameters:
///   - inputFile: The input `.proto` file.
///   - protoDirectoryPath: The root path to the source `.proto` files used as the reference for relative path naming schemes.
///   - outputDirectory: The directory in which generated source files are created.
///   - outputExtension: The file extension to be appended to generated files in-place of `.proto`.
/// - Returns: The expected output file path.
func deriveOutputFilePath(
  for inputFile: URL,
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

  let outputFileComponents = relativePathComponents + [lastPathComponent]
  var outputFilePath = outputDirectory
  for outputFileComponent in outputFileComponents {
    outputFilePath.append(component: outputFileComponent)
  }
  return outputFilePath
}

// Entry-point when using Package manifest
extension GRPCProtobufGenerator: BuildToolPlugin {
  /// Create build commands, the entry-point when using a Package manifest.
  func createBuildCommands(context: PluginContext, target: Target) async throws -> [Command] {
    guard let swiftTarget = target as? SwiftSourceModuleTarget else {
      throw PluginError.incompatibleTarget(target.name)
    }
    let configFiles = swiftTarget.sourceFiles(withSuffix: configFileName).map { $0.url }
    let inputFiles = swiftTarget.sourceFiles(withSuffix: ".proto").map { $0.url }
    return try createBuildCommands(
      pluginWorkDirectory: context.pluginWorkDirectoryURL,
      tool: context.tool,
      inputFiles: inputFiles,
      configFiles: configFiles,
      targetName: target.name
    )
  }
}

#if canImport(XcodeProjectPlugin)
import XcodeProjectPlugin

// Entry-point when using Xcode projects
extension GRPCProtobufGenerator: XcodeBuildToolPlugin {
  /// Create build commands, the entry-point when using an Xcode project.
  func createBuildCommands(context: XcodePluginContext, target: XcodeTarget) throws -> [Command] {
    let configFiles = target.inputFiles.filter {
      $0.url.lastPathComponent == configFileName
    }.map { $0.url }
    let inputFiles = target.inputFiles.filter { $0.url.lastPathComponent.hasSuffix(".proto") }.map {
      $0.url
    }
    return try createBuildCommands(
      pluginWorkDirectory: context.pluginWorkDirectoryURL,
      tool: context.tool,
      inputFiles: inputFiles,
      configFiles: configFiles,
      targetName: target.displayName
    )
  }
}
#endif
