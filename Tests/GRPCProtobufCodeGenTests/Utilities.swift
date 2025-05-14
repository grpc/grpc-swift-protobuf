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
import GRPCProtobufCodeGen
import SwiftProtobuf
import SwiftProtobufPluginLibrary
import Testing

import struct GRPCCodeGen.CodeGenerationRequest
import struct GRPCCodeGen.CodeGenerator

protocol UsesDescriptorSet {
  static var descriptorSetName: String { get }
  static var fileDescriptorName: String { get }

  static var descriptorSet: DescriptorSet { get throws }
  static var fileDescriptor: FileDescriptor { get throws }
}

extension UsesDescriptorSet {
  static var descriptorSet: DescriptorSet {
    get throws {
      try loadDescriptorSet(named: Self.descriptorSetName)
    }
  }

  static var fileDescriptor: FileDescriptor {
    get throws {
      let descriptorSet = try Self.descriptorSet
      if let fileDescriptor = descriptorSet.fileDescriptor(named: fileDescriptorName + ".proto") {
        return fileDescriptor
      } else {
        throw MissingFileDescriptor()
      }
    }
  }
}

struct MissingFileDescriptor: Error {}

private func loadDescriptorSet(
  named name: String,
  withExtension extension: String = "pb"
) throws -> DescriptorSet {
  let maybeURL = Bundle.module.url(
    forResource: name,
    withExtension: `extension`,
    subdirectory: "Generated"
  )

  let url = try #require(maybeURL)
  let data = try Data(contentsOf: url)
  let descriptorSet = try Google_Protobuf_FileDescriptorSet(serializedBytes: data)
  return DescriptorSet(proto: descriptorSet)
}

func parseDescriptor(
  _ descriptor: FileDescriptor,
  extraModuleImports: [String] = [],
  accessLevel: CodeGenerator.Config.AccessLevel = .internal
) throws -> CodeGenerationRequest {
  let parser = ProtobufCodeGenParser(
    protoFileModuleMappings: .init(),
    extraModuleImports: extraModuleImports,
    accessLevel: accessLevel,
    moduleNames: .defaults
  )
  return try parser.parse(descriptor: descriptor)
}
