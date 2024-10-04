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

import GRPCProtobufCodeGen
import Testing

@Suite("CamelCaser")
struct CamelCaserTests {
  @Test(
    "Convert to lower camel case",
    arguments: [
      ("ImportCsv", "importCsv"),
      ("ImportCSV", "importCSV"),
      ("CSVImport", "csvImport"),
      ("importCSV", "importCSV"),
      ("FOOBARImport", "foobarImport"),
      ("FOO_BARImport", "foo_barImport"),
      ("My_CSVImport", "my_CSVImport"),
      ("_CSVImport", "_csvImport"),
      ("V2Request", "v2Request"),
      ("V2_Request", "v2_Request"),
      ("CSV", "csv"),
      ("I", "i"),
      ("i", "i"),
      ("I_", "i_"),
      ("_", "_"),
      ("", ""),
    ]
  )
  func toLowerCamelCase(_ input: String, expectedOutput: String) async throws {
    #expect(CamelCaser.toLowerCamelCase(input) == expectedOutput)
  }
}
