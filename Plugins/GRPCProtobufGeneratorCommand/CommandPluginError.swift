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
  case missingArgumentValue
  case invalidArgumentValue(name: String, value: String)
  case missingInputFile
  case unknownOption(String)
}

extension CommandPluginError: CustomStringConvertible {
  var description: String {
    switch self {
    case .missingArgumentValue:
      "Provided option does not have a value."
    case .invalidArgumentValue(let name, let value):
      "Invalid value '\(value)', for '\(name)'."
    case .missingInputFile:
      "No input file(s) specified."
    case .unknownOption(let value):
      "Provided option is unknown: \(value)."
    }
  }
}
