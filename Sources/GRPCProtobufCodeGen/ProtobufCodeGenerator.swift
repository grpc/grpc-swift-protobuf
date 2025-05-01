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

package import GRPCCodeGen
package import SwiftProtobufPluginLibrary

@available(gRPCSwiftProtobuf 1.0, *)
package struct ProtobufCodeGenerator {
  internal var config: ProtobufCodeGenerator.Config

  package init(
    config: ProtobufCodeGenerator.Config
  ) {
    self.config = config
  }

  package func generateCode(
    fileDescriptor: FileDescriptor,
    protoFileModuleMappings: ProtoFileToModuleMappings,
    extraModuleImports: [String],
    availabilityOverrides: [(os: String, version: String)] = []
  ) throws -> String {
    let parser = ProtobufCodeGenParser(
      protoFileModuleMappings: protoFileModuleMappings,
      extraModuleImports: extraModuleImports,
      accessLevel: self.config.accessLevel,
      moduleNames: self.config.moduleNames
    )

    var codeGeneratorConfig = GRPCCodeGen.CodeGenerator.Config(
      accessLevel: self.config.accessLevel,
      accessLevelOnImports: self.config.accessLevelOnImports,
      client: self.config.generateClient,
      server: self.config.generateServer,
      indentation: self.config.indentation
    )
    codeGeneratorConfig.grpcCoreModuleName = self.config.moduleNames.grpcCore

    if availabilityOverrides.isEmpty {
      codeGeneratorConfig.availability = .default
    } else {
      codeGeneratorConfig.availability = .custom(
        availabilityOverrides.map { (os, version) in
          .init(os: os, version: version)
        }
      )
    }

    let codeGenerator = GRPCCodeGen.CodeGenerator(config: codeGeneratorConfig)

    let codeGenerationRequest = try parser.parse(descriptor: fileDescriptor)
    let sourceFile = try codeGenerator.generate(codeGenerationRequest)
    return sourceFile.contents
  }
}

@available(gRPCSwiftProtobuf 1.0, *)
extension ProtobufCodeGenerator {
  package struct Config {
    package var accessLevel: GRPCCodeGen.CodeGenerator.Config.AccessLevel
    package var accessLevelOnImports: Bool

    package var generateClient: Bool
    package var generateServer: Bool

    package var indentation: Int
    package var moduleNames: ModuleNames

    package struct ModuleNames {
      package var grpcCore: String
      package var grpcProtobuf: String
      package var swiftProtobuf: String

      package static let defaults = Self(
        grpcCore: "GRPCCore",
        grpcProtobuf: "GRPCProtobuf",
        swiftProtobuf: "SwiftProtobuf"
      )
    }

    package static var defaults: Self {
      Self(
        accessLevel: .internal,
        accessLevelOnImports: false,
        generateClient: true,
        generateServer: true,
        indentation: 4,
        moduleNames: .defaults
      )
    }
  }
}
