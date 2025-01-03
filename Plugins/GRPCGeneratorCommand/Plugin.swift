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
struct GRPCGeneratorCommandPlugin: CommandPlugin {
  /// Perform command, the entry-point when using a Package manifest.
  func performCommand(context: PluginContext, arguments: [String]) async throws {

    // MARK: Configuration
    let commandConfig: CommandConfiguration
    do {
      commandConfig = try CommandConfiguration(arguments: arguments)
    } catch PluginError.helpRequested {
      Flag.printHelp()
      return  // don't throw, the user requested this
    } catch {
      Flag.printHelp()
      throw error
    }
    let config = commandConfig.common

    let inputFiles = inputFiles(from: arguments)
    print("InputFiles: \(inputFiles.joined(separator: ", "))")

    let protocPath = try deriveProtocPath(using: config, tool: context.tool)
    let protocGenGRPCSwiftPath = try context.tool(named: "protoc-gen-grpc-swift").url
    let protocGenSwiftPath = try context.tool(named: "protoc-gen-swift").url

    let outputDirectory =
      config.outputPath.map { URL(fileURLWithPath: $0) } ?? context.pluginWorkDirectoryURL
    print("Generated files will be written to: '\(outputDirectory.relativePath)'")

    let inputFileURLs = inputFiles.map { URL(fileURLWithPath: $0) }

    // MARK: proto-gen-grpc-swift
    if config.client != false || config.server != false {
      let arguments = constructProtocGenGRPCSwiftArguments(
        config: config,
        using: config.fileNaming,
        inputFiles: inputFileURLs,
        protoDirectoryPaths: inputFileURLs.map { $0.deletingLastPathComponent() },
        protocGenGRPCSwiftPath: protocGenGRPCSwiftPath,
        outputDirectory: outputDirectory
      )

      printProtocInvocation(protocPath, arguments)
      if !commandConfig.dryRun {
        let process = try Process.run(protocPath, arguments: arguments)
        process.waitUntilExit()

        if process.terminationReason == .exit && process.terminationStatus == 0 {
          print("Generated gRPC Swift files for \(inputFiles.joined(separator: ", ")).")
        } else {
          let problem = "\(process.terminationReason):\(process.terminationStatus)"
          Diagnostics.error("Generating gRPC Swift files failed: \(problem)")
        }
      }
    }

    // MARK: proto-gen-swift
    if config.message != false {
      let arguments = constructProtocGenSwiftArguments(
        config: config,
        using: config.fileNaming,
        inputFiles: inputFileURLs,
        protoDirectoryPaths: inputFileURLs.map { $0.deletingLastPathComponent() },
        protocGenSwiftPath: protocGenSwiftPath,
        outputDirectory: outputDirectory
      )

      printProtocInvocation(protocPath, arguments)
      if !commandConfig.dryRun {
        let process = try Process.run(protocPath, arguments: arguments)
        process.waitUntilExit()

        if process.terminationReason == .exit && process.terminationStatus == 0 {
          print("Generated protobuf message Swift files for \(inputFiles.joined(separator: ", ")).")
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
  print("protoc invocation:")
  print("  \(executableURL.relativePath) \\")
  for argument in arguments[..<arguments.count.advanced(by: -1)] {
    print("    \(argument) \\")
  }
  if let lastArgument = arguments.last {
    print("    \(lastArgument)")
  }
}
