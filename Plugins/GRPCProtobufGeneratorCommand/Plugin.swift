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
  /// Command plugin common code
  func performCommand(
    arguments: [String],
    tool: (String) throws -> PluginContext.Tool,
    pluginWorkDirectoryURL: URL
  ) throws {
    let flagsAndOptions: [String]
    let inputFiles: [String]

    let separatorCount = arguments.filter { $0 == CommandConfig.parameterGroupSeparator }.count
    switch separatorCount {
    case 0:
      var argExtractor = ArgumentExtractor(arguments)
      // check if help requested
      if argExtractor.extractFlag(named: OptionsAndFlags.help.rawValue) > 0 {
        OptionsAndFlags.printHelp(requested: true)
        return
      }

      inputFiles = arguments
      flagsAndOptions = []

    case 1:
      let splitIndex = arguments.firstIndex(of: CommandConfig.parameterGroupSeparator)!
      flagsAndOptions = Array(arguments[..<splitIndex])
      inputFiles = Array(arguments[(splitIndex).advanced(by: 1)...])

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

      try executeProtocInvocation(
        executableURL: protocPath,
        arguments: arguments,
        verbose: commandConfig.verbose,
        dryRun: commandConfig.dryRun
      )

      if !commandConfig.dryRun {
        Stderr.print("Generated gRPC Swift files for \(inputFiles.joined(separator: ", ")).")
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

      let completionStatus = try executeProtocInvocation(
        executableURL: protocPath,
        arguments: arguments,
        verbose: commandConfig.verbose,
        dryRun: commandConfig.dryRun
      )

      if !commandConfig.dryRun {
        Stderr.print(
          "Generated protobuf message Swift files for \(inputFiles.joined(separator: ", "))."
        )
      }
    }
  }
}

/// Execute a single invocation of `protoc`, printing output and if in verbose mode the invocation
/// - Parameters:
///   - executableURL: The path to the `protoc` executable.
///   - arguments: The arguments to be passed to `protoc`.
///   - verbose: Whether or not to print verbose output
///   - dryRun: If this invocation is a dry-run, i.e. will not actually be executed
func executeProtocInvocation(
  executableURL: URL,
  arguments: [String],
  verbose: Bool,
  dryRun: Bool
) throws {
  if verbose {
    Stderr.print("\(executableURL.absoluteStringNoScheme) \\")
    Stderr.print("  \(arguments.joined(separator: " \\\n  "))")
  }

  if dryRun {
    return
  }

  let process = Process()
  process.executableURL = executableURL
  process.arguments = arguments

  let outputPipe = Pipe()
  let errorPipe = Pipe()
  process.standardOutput = outputPipe
  process.standardError = errorPipe

  do {
    try process.run()
  } catch {
    try printProtocOutput(outputPipe, verbose: verbose)
    let stdErr: String?
    if let errorData = try errorPipe.fileHandleForReading.readToEnd() {
      stdErr = String(decoding: errorData, as: UTF8.self)
    } else {
      stdErr = nil
    }
    throw CommandPluginError.generationFailure(
      errorDescription: "\(error)",
      executable: executableURL.absoluteStringNoScheme,
      arguments: arguments,
      stdErr: stdErr
    )
  }
  process.waitUntilExit()

  try printProtocOutput(outputPipe, verbose: verbose)

  guard process.terminationReason == .exit && process.terminationStatus == 0 else {
    let stdErr: String?
    if let errorData = try errorPipe.fileHandleForReading.readToEnd() {
      stdErr = String(decoding: errorData, as: UTF8.self)
    } else {
      stdErr = nil
    }
    let problem = "\(process.terminationReason):\(process.terminationStatus)"
    throw CommandPluginError.generationFailure(
      errorDescription: problem,
      executable: executableURL.absoluteStringNoScheme,
      arguments: arguments,
      stdErr: stdErr
    )
  }

  return
}

func printProtocOutput(_ stdOut: Pipe, verbose: Bool) throws {
  let prefix = "\t"

  if verbose, let outputData = try stdOut.fileHandleForReading.readToEnd() {
    let output = String(decoding: outputData, as: UTF8.self)
    let lines = output.split { $0.isNewline }
    print("protoc output:")
    for line in lines {
      print("\(prefix)\(line)")
    }
  }
}
