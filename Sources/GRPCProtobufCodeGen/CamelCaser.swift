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

package enum CamelCaser {
  /// Converts a string from upper camel case to lower camel case.
  package static func toLowerCamelCase(_ input: String) -> String {
    guard let indexOfFirstLowercase = input.firstIndex(where: { $0.isLowercase }) else {
      return input.lowercased()
    }

    if indexOfFirstLowercase == input.startIndex {
      // `input` already begins with a lower case letter. As in: "importCSV".
      return input
    } else if indexOfFirstLowercase == input.index(after: input.startIndex) {
      // The second character in `input` is lower case. As in: "ImportCSV".
      // returns "importCSV"
      return input[input.startIndex].lowercased() + input[indexOfFirstLowercase...]
    } else {
      // The first lower case character is further within `input`. Tentatively, `input` begins
      // with one or more abbreviations. Therefore, the last encountered upper case character
      // could be the beginning of the next word. As in: "FOOBARImportCSV".

      let leadingAbbreviation = input[..<input.index(before: indexOfFirstLowercase)]
      let followingWords = input[input.index(before: indexOfFirstLowercase)...]

      // returns "foobarImportCSV"
      return leadingAbbreviation.lowercased() + followingWords
    }
  }
}
