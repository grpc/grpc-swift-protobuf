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

package struct ProtobufCodeGenerator {
  internal var config: GRPCCodeGen.CodeGenerator.Config

  package init(
    config: GRPCCodeGen.CodeGenerator.Config
  ) {
    self.config = config
  }

  package func generateCode(
    fileDescriptor: FileDescriptor,
    protoFileModuleMappings: ProtoFileToModuleMappings,
    extraModuleImports: [String]
  ) throws -> String {
    let parser = ProtobufCodeGenParser(
      protoFileModuleMappings: protoFileModuleMappings,
      extraModuleImports: extraModuleImports,
      accessLevel: self.config.accessLevel
    )
    let codeGenerator = GRPCCodeGen.CodeGenerator(config: self.config)

    let codeGenerationRequest = try parser.parse(descriptor: fileDescriptor)
    let sourceFile = try codeGenerator.generate(codeGenerationRequest)
    return sourceFile.contents
  }
}
