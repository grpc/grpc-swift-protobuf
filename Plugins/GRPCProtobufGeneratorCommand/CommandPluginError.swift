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
  case generationFailure(
    errorDescription: String,
    executable: String?,
    arguments: [String]?,
    stdErr: String?
  )
  case tooManyParameterSeparators
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
    case .generationFailure(let errorDescription, let executable, let arguments, let stdErr):
      var message = "Code generation failed with: \(errorDescription)."
      if let executable {
        message += "\n\tExecutable: \(executable)"
      }
      if let arguments {
        message += "\n\tArguments: \(arguments.joined(separator: " "))"
      }
      if let stdErr {
        message += "\n\tprotoc error output:"
        message += "\n\t\(stdErr)"
      }
      return message
    case .tooManyParameterSeparators:
      return "Unexpected parameter structure, too many '--' separators."
    }
  }
}
