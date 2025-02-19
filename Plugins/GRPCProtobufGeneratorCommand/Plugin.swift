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
struct GRPCProtobufGeneratorCommandPlugin: CommandPlugin {
  /// Perform command, the entry-point when using a Package manifest.
  func performCommand(context: PluginContext, arguments: [String]) async throws {
    var argExtractor = ArgumentExtractor(arguments)

    if CommandConfig.helpRequested(argumentExtractor: &argExtractor) {
      OptionsAndFlags.printHelp(requested: true)
      return
    }

    // MARK: Configuration
    let commandConfig: CommandConfig
    let inputFiles: [String]
    do {
      (commandConfig, inputFiles) = try CommandConfig.parse(
        argumentExtractor: &argExtractor,
        pluginWorkDirectory: context.pluginWorkDirectoryURL
      )
    } catch {
      OptionsAndFlags.printHelp(requested: false)
      throw error
    }

    if commandConfig.verbose {
      Stderr.print("InputFiles: \(inputFiles.joined(separator: ", "))")
    }

    let config = commandConfig.common
    let protocPath = try deriveProtocPath(using: config, tool: context.tool)
    let protocGenGRPCSwiftPath = try context.tool(named: "protoc-gen-grpc-swift").url
    let protocGenSwiftPath = try context.tool(named: "protoc-gen-swift").url

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
          Diagnostics.error("Generating gRPC Swift files failed: \(problem)")
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
          Diagnostics.error("Generating Protobuf message Swift files failed: \(problem)")
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
