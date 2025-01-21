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
struct GRPCGeneratorPlugin {
  /// Code common to both invocation types: package manifest Xcode project
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
      guard let configFile = findApplicableConfigFor(file: inputFile, from: configs.keys.map { $0 })
      else {
        throw PluginError.noConfigurationFilesFound
      }
      guard let config = configs[configFile] else {
        throw PluginError.expectedConfigurationNotFound(configFile.relativePath)
      }

      let protocPath = try deriveProtocPath(using: config, tool: tool)
      let protoDirectoryPath = inputFile.deletingLastPathComponent()

      // unless *explicitly* opted-out
      if config.client != false || config.server != false {
        let grpcCommand = try protocGenGRPCSwiftCommand(
          inputFile: inputFile,
          configFile: configFile,
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
          configFile: configFile,
          config: config,
          protoDirectoryPath: protoDirectoryPath,
          protocPath: protocPath,
          protocGenSwiftPath: protocGenSwiftPath
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
) throws -> [URL: CommonConfiguration] {
  var configs: [URL: CommonConfiguration] = [:]
  for configFile in configurationFiles {
    let data = try Data(contentsOf: configFile)
    let configuration = try JSONDecoder().decode(ConfigurationFile.self, from: data)

    var config = CommonConfiguration(configurationFile: configuration)
    // hard-code full-path to avoid collisions since this goes into a temporary directory anyway
    config.fileNaming = .fullPath
    // the output directory mandated by the plugin system
    config.outputPath = String(pluginWorkDirectory.relativePath)
    configs[configFile] = config
  }
  return configs
}

/// Finds the most precisely relevant config file for a given proto file URL.
/// - Parameters:
///   - file: The path to the proto file to be matched.
///   - configFiles: The paths to all known configuration files.
/// - Returns: The path to the most precisely relevant config file if one is found, otherwise `nil`.
func findApplicableConfigFor(file: URL, from configFiles: [URL]) -> URL? {
  let filePathComponents = file.pathComponents
  for endComponent in (0 ..< filePathComponents.count).reversed() {
    for configFile in configFiles {
      if filePathComponents[..<endComponent]
        == configFile.pathComponents[..<(configFile.pathComponents.count - 1)]
      {
        return configFile
      }
    }
  }

  return nil
}

/// Construct the command to invoke `protoc` with the `proto-gen-grpc-swift` plugin.
/// - Parameters:
///   - inputFile: The input `.proto` file.
///   - configFile: The path file containing configuration for this operation.
///   - config: The configuration for this operation.
///   - protoDirectoryPath: The root path to the source `.proto` files used as the reference for relative path naming schemes.
///   - protocPath: The path to `protoc`
///   - protocGenGRPCSwiftPath: The path to `proto-gen-grpc-swift`.
/// - Returns: The command to invoke `protoc` with the `proto-gen-grpc-swift` plugin.
func protocGenGRPCSwiftCommand(
  inputFile: URL,
  configFile: URL,
  config: CommonConfiguration,
  protoDirectoryPath: URL,
  protocPath: URL,
  protocGenGRPCSwiftPath: URL
) throws -> PackagePlugin.Command {
  guard let fileNaming = config.fileNaming else {
    assertionFailure("Missing file naming strategy - should be hard-coded.")
    throw PluginError.missingFileNamingStrategy
  }

  guard let outputPath = config.outputPath else {
    assertionFailure("Missing output path - should be hard-coded.")
    throw PluginError.missingOutputPath
  }
  let outputPathURL = URL(fileURLWithPath: outputPath)

  let outputFilePath = deriveOutputFilePath(
    for: inputFile,
    using: fileNaming,
    protoDirectoryPath: protoDirectoryPath,
    outputDirectory: outputPathURL,
    outputExtension: "grpc.swift"
  )

  let arguments = constructProtocGenGRPCSwiftArguments(
    config: config,
    using: fileNaming,
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
///   - configFile: The path file containing configuration for this operation.
///   - config: The configuration for this operation.
///   - protoDirectoryPath: The root path to the source `.proto` files used as the reference for relative path naming schemes.
///   - protocPath: The path to `protoc`
///   - protocGenSwiftPath: The path to `proto-gen-grpc-swift`.
/// - Returns: The command to invoke `protoc` with the `proto-gen-swift` plugin.
func protocGenSwiftCommand(
  inputFile: URL,
  configFile: URL,
  config: CommonConfiguration,
  protoDirectoryPath: URL,
  protocPath: URL,
  protocGenSwiftPath: URL
) throws -> PackagePlugin.Command {
  guard let fileNaming = config.fileNaming else {
    assertionFailure("Missing file naming strategy - should be hard-coded.")
    throw PluginError.missingFileNamingStrategy
  }

  guard let outputPath = config.outputPath else {
    assertionFailure("Missing output path - should be hard-coded.")
    throw PluginError.missingOutputPath
  }
  let outputPathURL = URL(fileURLWithPath: outputPath)

  let outputFilePath = deriveOutputFilePath(
    for: inputFile,
    using: fileNaming,
    protoDirectoryPath: protoDirectoryPath,
    outputDirectory: outputPathURL,
    outputExtension: "pb.swift"
  )

  let arguments = constructProtocGenSwiftArguments(
    config: config,
    using: fileNaming,
    inputFiles: [inputFile],
    protoDirectoryPaths: [protoDirectoryPath],
    protocGenSwiftPath: protocGenSwiftPath,
    outputDirectory: outputPathURL
  )

  return Command.buildCommand(
    displayName: "Generating protobuf Swift files for \(inputFile.relativePath)",
    executable: protocPath,
    arguments: arguments,
    inputFiles: [inputFile, protocGenSwiftPath],
    outputFiles: [outputFilePath]
  )
}

// Entry-point when using Package manifest
extension GRPCGeneratorPlugin: BuildToolPlugin, LocalizedError {
  /// Create build commands, the entry-point when using a Package manifest.
  func createBuildCommands(context: PluginContext, target: Target) async throws -> [Command] {
    guard let swiftTarget = target as? SwiftSourceModuleTarget else {
      throw PluginError.incompatibleTarget(target.name)
    }
    let configFiles = swiftTarget.sourceFiles(withSuffix: "grpc-swift-config.json").map { $0.url }
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
extension GRPCGeneratorPlugin: XcodeBuildToolPlugin {
  /// Create build commands, the entry-point when using an Xcode project.
  func createBuildCommands(context: XcodePluginContext, target: XcodeTarget) throws -> [Command] {
    let configFiles = target.inputFiles.filter {
      $0.url.lastPathComponent == "grpc-swift-config.json"
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
