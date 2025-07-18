/*
 * Copyright 2025, gRPC Authors All rights reserved.
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

enum CommandPluginError: Error {
  case invalidArgumentValue(name: String, value: String)
  case missingInputFile
  case unknownOption(String)
  case unknownAccessLevel(String)
  case unknownFileNamingStrategy(String)
  case conflictingFlags(String, String)
  case invalidInputFiles([String])
  case generationFailure(
    executable: String,
    arguments: [String],
    stdErr: String?
  )
}

extension CommandPluginError: CustomStringConvertible {
  var description: String {
    switch self {
    case .invalidArgumentValue(let name, let value):
      return "Invalid value '\(value)', for '\(name)'."
    case .missingInputFile:
      return "No input file(s) specified."
    case .unknownOption(let name):
      return "Provided option is unknown: \(name)."
    case .unknownAccessLevel(let value):
      return "Provided access level is unknown: \(value)."
    case .unknownFileNamingStrategy(let value):
      return "Provided file naming strategy is unknown: \(value)."
    case .conflictingFlags(let flag1, let flag2):
      return "Provided flags conflict: '\(flag1)' and '\(flag2)'."

    case .invalidInputFiles(let files):
      var lines: [String] = []
      lines.append("Invalid input file(s)")
      lines.append("")
      lines.append("Found \(files.count) input(s) not ending in '.proto':")
      for file in files {
        lines.append("- \(file)")
      }
      lines.append("")
      lines.append("All options must be before '--', and all input files must be")
      lines.append("after '--'. Input files must end in '.proto'.")
      lines.append("")
      lines.append("See --help for more information.")
      return lines.joined(separator: "\n")

    case .generationFailure(let executable, let arguments, let stdErr):
      var lines: [String] = []
      lines.append("protoc failed to generate code")
      lines.append("")
      lines.append(String(repeating: "-", count: 80))
      lines.append("Command run:")
      lines.append("")
      lines.append("\(executable) \\")
      var iterator = arguments.makeIterator()
      var current = iterator.next()
      while let currentArg = current {
        var nextArg = iterator.next()
        defer { current = nextArg }

        if nextArg != nil {
          lines.append("  \(currentArg) \\")
        } else {
          lines.append("  \(currentArg)")
        }
      }

      if let stdErr {
        lines.append("")
        lines.append(String(repeating: "-", count: 80))
        lines.append("Error output (stderr):")
        lines.append("")
        lines.append(stdErr)
      }

      return lines.joined(separator: "\n")
    }
  }
}
