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

package struct CamelCaser {
  /// Converts a string from upper camel case to lower camel case.
  package static func toLowerCamelCase(_ s: String) -> String {
    if s.isEmpty { return "" }

    let indexOfFirstLowerCase = s.firstIndex(where: { $0 != "_" && $0.lowercased() == String($0) })

    if let indexOfFirstLowerCase {
      if indexOfFirstLowerCase == s.startIndex {
        // `s` already begins with a lower case letter. As in: "importCSV".
        return s
      } else if indexOfFirstLowerCase == s.index(after: s.startIndex) {
        // The second character in `s` is lower case. As in: "ImportCSV".
        return s[s.startIndex].lowercased() + s[indexOfFirstLowerCase...]  // -> "importCSV"
      } else {
        // The first lower case character is further within `s`. Tentatively, `s` begins with one or
        // more abbreviations. Therefore, the last encountered upper case character could be the
        // beginning of the next word. As in: "FOOBARImportCSV".

        let leadingAbbreviation = s[..<s.index(before: indexOfFirstLowerCase)]
        let followingWords = s[s.index(before: indexOfFirstLowerCase)...]

        return leadingAbbreviation.lowercased() + followingWords  // -> "foobarImportCSV"
      }
    } else {
      // `s` did not contain any lower case letter.
      return s.lowercased()
    }
  }
}
