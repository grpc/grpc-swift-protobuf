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

/// The configuration used when generating code whether called from the build or command plugin.
struct GenerationConfig {
  /// The visibility of the generated files.
  enum Visibility: String {
    /// The generated files should have `internal` access level.
    case `internal` = "Internal"
    /// The generated files should have `public` access level.
    case `public` = "Public"
    /// The generated files should have `package` access level.
    case `package` = "Package"
  }
  /// The naming of output files with respect to the path of the source file.
  ///
  /// For an input of `foo/bar/baz.proto` the following output file will be generated:
  /// - `FullPath`: `foo/bar/baz.grpc.swift`
  /// - `PathToUnderscore`: `foo_bar_baz.grpc.swift`
  /// - `DropPath`: `baz.grpc.swift`
  enum FileNaming: String, Codable {
    /// Replicate the input file path with the output file(s).
    case fullPath = "FullPath"
    /// Convert path directory delimiters to underscores.
    case pathToUnderscores = "PathToUnderscores"
    /// Generate output files using only the base name of the inout file, ignoring the path.
    case dropPath = "DropPath"
  }

  /// The visibility of the generated files.
  var visibility: Visibility
  /// Whether server code is generated.
  var server: Bool
  /// Whether client code is generated.
  var client: Bool
  /// Whether message code is generated.
  var message: Bool
  /// The naming of output files with respect to the path of the source file.
  var fileNaming: FileNaming
  /// Whether imports should have explicit access levels.
  var useAccessLevelOnImports: Bool

  /// Specify the directory in which to search for imports.
  ///
  /// May be specified multiple times; directories will be searched in order.
  /// The target source directory is always appended to the import paths.
  var importPaths: [String]

  /// The path to the `protoc` binary.
  ///
  /// If this is not set, Swift Package Manager will try to find the tool itself.
  var protocPath: String?

  /// The path into which the generated source files are created.
  var outputPath: String
}
