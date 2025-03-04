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

// Entry-point when using Package manifest
extension GRPCProtobufGenerator: BuildToolPlugin {
  func createBuildCommands(context: PluginContext, target: Target) async throws -> [Command] {
    guard let swiftTarget = target as? SwiftSourceModuleTarget else {
      throw BuildPluginError.incompatibleTarget(target.name)
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

@main
struct GRPCProtobufGenerator {
  /// Build plugin common code
  func createBuildCommands(
    pluginWorkDirectory: URL,
    tool: (String) throws -> PluginContext.Tool,
    inputFiles: [URL],
    configFiles: [URL],
    targetName: String
  ) throws -> [Command] {
    let configs = try readConfigFiles(configFiles, pluginWorkDirectory: pluginWorkDirectory)

    let protocGenGRPCSwiftPath = try tool("protoc-gen-grpc-swift").url
    let protocGenSwiftPath = try tool("protoc-gen-swift").url

    var commands: [Command] = []
    for inputFile in inputFiles {
      guard let (configFilePath, config) = configs.findApplicableConfig(for: inputFile) else {
        throw BuildPluginError.noConfigFilesFound
      }

      let protocPath = try deriveProtocPath(using: config, tool: tool)
      let protoDirectoryPaths: [String]
      if config.importPaths.isEmpty {
        protoDirectoryPaths = [configFilePath.deletingLastPathComponent().absoluteStringNoScheme]
      } else {
        protoDirectoryPaths = config.importPaths
      }

      // unless *explicitly* opted-out
      if config.clients || config.servers {
        let grpcCommand = try protocGenGRPCSwiftCommand(
          inputFile: inputFile,
          config: config,
          baseDirectoryPath: configFilePath.deletingLastPathComponent(),
          protoDirectoryPaths: protoDirectoryPaths,
          protocPath: protocPath,
          protocGenGRPCSwiftPath: protocGenGRPCSwiftPath,
          configFilePath: configFilePath
        )
        commands.append(grpcCommand)
      }

      // unless *explicitly* opted-out
      if config.messages {
        let protoCommand = try protocGenSwiftCommand(
          inputFile: inputFile,
          config: config,
          baseDirectoryPath: configFilePath.deletingLastPathComponent(),
          protoDirectoryPaths: protoDirectoryPaths,
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

/// Reads the config files at the supplied URLs into memory
/// - Parameter configFilePaths: URLs from which to load config
/// - Returns: A map of source URLs to loaded config
func readConfigFiles(
  _ configFilePaths: [URL],
  pluginWorkDirectory: URL
) throws -> [URL: GenerationConfig] {
  var configs: [URL: GenerationConfig] = [:]
  for configFilePath in configFilePaths {
    let data = try Data(contentsOf: configFilePath)
    let config = try JSONDecoder().decode(BuildPluginConfig.self, from: data)

    // the output directory mandated by the plugin system
    configs[configFilePath] = GenerationConfig(
      buildPluginConfig: config,
      configFilePath: configFilePath,
      outputPath: pluginWorkDirectory
    )
  }
  return configs
}

extension [URL: GenerationConfig] {
  /// Finds the most relevant config file for a given proto file URL.
  ///
  /// The most relevant config file is the lowest of config files which are either a sibling or a parent in the file heirarchy.
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

/// Construct the command to invoke `protoc` with the `protoc-gen-grpc-swift` plugin.
/// - Parameters:
///   - inputFile: The input `.proto` file.
///   - config: The config for this operation.
///   - baseDirectoryPath: The root path to the source `.proto` files used as the reference for relative path naming schemes.
///   - protoDirectoryPaths: The paths passed to `protoc` in which to look for imported proto files.
///   - protocPath: The path to `protoc`
///   - protocGenGRPCSwiftPath: The path to `protoc-gen-grpc-swift`.
///   - configFilePath: The path to the config file in use.
/// - Returns: The command to invoke `protoc` with the `protoc-gen-grpc-swift` plugin.
func protocGenGRPCSwiftCommand(
  inputFile: URL,
  config: GenerationConfig,
  baseDirectoryPath: URL,
  protoDirectoryPaths: [String],
  protocPath: URL,
  protocGenGRPCSwiftPath: URL,
  configFilePath: URL
) throws -> PackagePlugin.Command {
  let outputPathURL = URL(fileURLWithPath: config.outputPath)

  let outputFilePath = deriveOutputFilePath(
    protoFile: inputFile,
    baseDirectoryPath: baseDirectoryPath,
    outputDirectory: outputPathURL,
    outputExtension: "grpc.swift"
  )

  let arguments = constructProtocGenGRPCSwiftArguments(
    config: config,
    fileNaming: config.fileNaming,
    inputFiles: [inputFile],
    protoDirectoryPaths: protoDirectoryPaths,
    protocGenGRPCSwiftPath: protocGenGRPCSwiftPath,
    outputDirectory: outputPathURL
  )

  return Command.buildCommand(
    displayName: "Generating gRPC Swift files for \(inputFile.absoluteStringNoScheme)",
    executable: protocPath,
    arguments: arguments,
    inputFiles: [
      inputFile,
      protocGenGRPCSwiftPath,
      configFilePath,
    ],
    outputFiles: [outputFilePath]
  )
}

/// Construct the command to invoke `protoc` with the `protoc-gen-swift` plugin.
/// - Parameters:
///   - inputFile: The input `.proto` file.
///   - config: The config for this operation.
///   - baseDirectoryPath: The root path to the source `.proto` files used as the reference for relative path naming schemes.
///   - protoDirectoryPaths: The paths passed to `protoc` in which to look for imported proto files.
///   - protocPath: The path to `protoc`
///   - protocGenSwiftPath: The path to `protoc-gen-grpc-swift`.
///   - configFilePath: The path to the config file in use.
/// - Returns: The command to invoke `protoc` with the `protoc-gen-swift` plugin.
func protocGenSwiftCommand(
  inputFile: URL,
  config: GenerationConfig,
  baseDirectoryPath: URL,
  protoDirectoryPaths: [String],
  protocPath: URL,
  protocGenSwiftPath: URL,
  configFilePath: URL
) throws -> PackagePlugin.Command {
  let outputPathURL = URL(fileURLWithPath: config.outputPath)

  let outputFilePath = deriveOutputFilePath(
    protoFile: inputFile,
    baseDirectoryPath: baseDirectoryPath,
    outputDirectory: outputPathURL,
    outputExtension: "pb.swift"
  )

  let arguments = constructProtocGenSwiftArguments(
    config: config,
    fileNaming: config.fileNaming,
    inputFiles: [inputFile],
    protoDirectoryPaths: protoDirectoryPaths,
    protocGenSwiftPath: protocGenSwiftPath,
    outputDirectory: outputPathURL
  )

  return Command.buildCommand(
    displayName: "Generating Swift Protobuf files for \(inputFile.absoluteStringNoScheme)",
    executable: protocPath,
    arguments: arguments,
    inputFiles: [
      inputFile,
      protocGenSwiftPath,
      configFilePath,
    ],
    outputFiles: [outputFilePath]
  )
}

/// Derive the expected output file path to match the behavior of the `protoc-gen-swift`
/// and `protoc-gen-grpc-swift` `protoc` plugins using the `PathToUnderscores` naming scheme.
///
/// This means the generated file for an input proto file called "foo/bar/baz.proto" will
/// have the name "foo\_bar\_baz.proto".
///
/// - Parameters:
///   - protoFile: The path of the input `.proto` file.
///   - baseDirectoryPath: The root path to the source `.proto` files used as the reference for
///     relative path naming schemes.
///   - outputDirectory: The directory in which generated source files are created.
///   - outputExtension: The file extension to be appended to generated files in-place of `.proto`.
/// - Returns: The expected output file path.
func deriveOutputFilePath(
  protoFile: URL,
  baseDirectoryPath: URL,
  outputDirectory: URL,
  outputExtension: String
) -> URL {
  // Replace the extension (".proto") with the new extension (".grpc.swift"
  // or ".pb.swift").
  precondition(protoFile.pathExtension == "proto")
  let fileName = String(protoFile.lastPathComponent.dropLast(5) + outputExtension)

  // find the inputFile path relative to the proto directory
  var relativePathComponents = protoFile.deletingLastPathComponent().pathComponents
  for protoDirectoryPathComponent in baseDirectoryPath.pathComponents {
    if relativePathComponents.first == protoDirectoryPathComponent {
      relativePathComponents.removeFirst()
    } else {
      break
    }
  }

  relativePathComponents.append(fileName)
  let path = relativePathComponents.joined(separator: "_")
  return outputDirectory.appending(path: path)
}
