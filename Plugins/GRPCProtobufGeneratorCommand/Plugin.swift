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

extension GRPCProtobufGeneratorCommandPlugin: CommandPlugin {
  /// Perform command, the entry-point when using a Package manifest.
  func performCommand(context: PluginContext, arguments: [String]) async throws {
    try self.performCommand(
      arguments: arguments,
      tool: context.tool,
      pluginWorkDirectoryURL: context.pluginWorkDirectoryURL
    )
  }
}

#if canImport(XcodeProjectPlugin)
import XcodeProjectPlugin

// Entry-point when using Xcode projects
extension GRPCProtobufGeneratorCommandPlugin: XcodeCommandPlugin {
  /// Perform command, the entry-point when using an Xcode project.
  func performCommand(context: XcodeProjectPlugin.XcodePluginContext, arguments: [String]) throws {
    try self.performCommand(
      arguments: arguments,
      tool: context.tool,
      pluginWorkDirectoryURL: context.pluginWorkDirectoryURL
    )
  }
}
#endif

@main
struct GRPCProtobufGeneratorCommandPlugin {
  /// Command plugin code common to both invocation types: package manifest Xcode project
  func performCommand(
    arguments: [String],
    tool: (String) throws -> PluginContext.Tool,
    pluginWorkDirectoryURL: URL
  ) throws {
    let groups = arguments.split(separator: "--")
    let flagsAndOptions: [String]
    let inputFiles: [String]
    switch groups.count {
    case 0:
      OptionsAndFlags.printHelp(requested: false)
      return

    case 1:
      inputFiles = Array(groups[0])
      flagsAndOptions = []

      var argExtractor = ArgumentExtractor(inputFiles)
      // check if help requested
      if argExtractor.extractFlag(named: OptionsAndFlags.help.rawValue) > 0 {
        OptionsAndFlags.printHelp(requested: true)
        return
      }

    case 2:
      flagsAndOptions = Array(groups[0])
      inputFiles = Array(groups[1])

    default:
      throw CommandPluginError.tooManyParameterSeparators
    }

    var argExtractor = ArgumentExtractor(flagsAndOptions)
    // help requested
    if argExtractor.extractFlag(named: OptionsAndFlags.help.rawValue) > 0 {
      OptionsAndFlags.printHelp(requested: true)
      return
    }

    // MARK: Configuration
    let commandConfig: CommandConfig
    do {
      commandConfig = try CommandConfig.parse(
        argumentExtractor: &argExtractor,
        pluginWorkDirectory: pluginWorkDirectoryURL
      )
    } catch {
      throw error
    }

    if commandConfig.verbose {
      Stderr.print("InputFiles: \(inputFiles.joined(separator: ", "))")
    }

    let config = commandConfig.common
    let protocPath = try deriveProtocPath(using: config, tool: tool)
    let protocGenGRPCSwiftPath = try tool("protoc-gen-grpc-swift").url
    let protocGenSwiftPath = try tool("protoc-gen-swift").url

    let outputDirectory = URL(fileURLWithPath: config.outputPath)
    if commandConfig.verbose {
      Stderr.print(
        "Generated files will be written to: '\(outputDirectory.absoluteStringNoScheme)'"
      )
    }

    let inputFileURLs = inputFiles.map { URL(fileURLWithPath: $0) }

    // MARK: protoc-gen-grpc-swift
    if config.clients || config.servers {
      let arguments = constructProtocGenGRPCSwiftArguments(
        config: config,
        fileNaming: config.fileNaming,
        inputFiles: inputFileURLs,
        protoDirectoryPaths: config.importPaths,
        protocGenGRPCSwiftPath: protocGenGRPCSwiftPath,
        outputDirectory: outputDirectory
      )

      if commandConfig.verbose || commandConfig.dryRun {
        printProtocInvocation(protocPath, arguments)
      }
      if !commandConfig.dryRun {
        let process = try Process.run(protocPath, arguments: arguments)
        process.waitUntilExit()

        if process.terminationReason == .exit, process.terminationStatus == 0 {
          if commandConfig.verbose {
            Stderr.print("Generated gRPC Swift files for \(inputFiles.joined(separator: ", ")).")
          }
        } else {
          let problem = "\(process.terminationReason):\(process.terminationStatus)"
          throw CommandPluginError.generationFailure
        }
      }
    }

    // MARK: protoc-gen-swift
    if config.messages {
      let arguments = constructProtocGenSwiftArguments(
        config: config,
        fileNaming: config.fileNaming,
        inputFiles: inputFileURLs,
        protoDirectoryPaths: config.importPaths,
        protocGenSwiftPath: protocGenSwiftPath,
        outputDirectory: outputDirectory
      )

      if commandConfig.verbose || commandConfig.dryRun {
        printProtocInvocation(protocPath, arguments)
      }
      if !commandConfig.dryRun {
        let process = try Process.run(protocPath, arguments: arguments)
        process.waitUntilExit()

        if process.terminationReason == .exit, process.terminationStatus == 0 {
          Stderr.print(
            "Generated protobuf message Swift files for \(inputFiles.joined(separator: ", "))."
          )
        } else {
          let problem = "\(process.terminationReason):\(process.terminationStatus)"
          throw CommandPluginError.generationFailure
        }
      }
    }
  }
}

/// Print a single invocation of `protoc`
/// - Parameters:
///   - executableURL: The path to the `protoc` executable.
///   - arguments: The arguments to be passed to `protoc`.
func printProtocInvocation(_ executableURL: URL, _ arguments: [String]) {
  Stderr.print("\(executableURL.absoluteStringNoScheme) \\")
  Stderr.print("  \(arguments.joined(separator: " \\\n  "))")
}
