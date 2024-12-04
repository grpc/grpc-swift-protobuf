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

internal import Foundation
internal import SwiftProtobuf
package import SwiftProtobufPluginLibrary

package import struct GRPCCodeGen.CodeGenerationRequest
package import struct GRPCCodeGen.Dependency
package import struct GRPCCodeGen.MethodDescriptor
package import struct GRPCCodeGen.Name
package import struct GRPCCodeGen.ServiceDescriptor
package import struct GRPCCodeGen.SourceGenerator

/// Parses a ``FileDescriptor`` object into a ``CodeGenerationRequest`` object.
package struct ProtobufCodeGenParser {
  let extraModuleImports: [String]
  let protoToModuleMappings: ProtoFileToModuleMappings
  let accessLevel: SourceGenerator.Config.AccessLevel

  package init(
    protoFileModuleMappings: ProtoFileToModuleMappings,
    extraModuleImports: [String],
    accessLevel: SourceGenerator.Config.AccessLevel
  ) {
    self.extraModuleImports = extraModuleImports
    self.protoToModuleMappings = protoFileModuleMappings
    self.accessLevel = accessLevel
  }

  package func parse(descriptor: FileDescriptor) throws -> CodeGenerationRequest {
    let namer = SwiftProtobufNamer(
      currentFile: descriptor,
      protoFileToModuleMappings: self.protoToModuleMappings
    )

    var header = descriptor.header
    // Ensuring there is a blank line after the header.
    if !header.isEmpty && !header.hasSuffix("\n\n") {
      header.append("\n")
    }

    let leadingTrivia = """
      // DO NOT EDIT.
      // swift-format-ignore-file
      //
      // Generated by the gRPC Swift generator plugin for the protocol buffer compiler.
      // Source: \(descriptor.name)
      //
      // For information on using the generated types, please see the documentation:
      //   https://github.com/grpc/grpc-swift

      """
    let lookupSerializer: (String) -> String = { messageType in
      "GRPCProtobuf.ProtobufSerializer<\(messageType)>()"
    }
    let lookupDeserializer: (String) -> String = { messageType in
      "GRPCProtobuf.ProtobufDeserializer<\(messageType)>()"
    }

    let services = descriptor.services.map {
      GRPCCodeGen.ServiceDescriptor(
        descriptor: $0,
        package: descriptor.package,
        protobufNamer: namer,
        file: descriptor
      )
    }

    return CodeGenerationRequest(
      fileName: descriptor.name,
      leadingTrivia: header + leadingTrivia,
      dependencies: self.codeDependencies(file: descriptor),
      services: services,
      lookupSerializer: lookupSerializer,
      lookupDeserializer: lookupDeserializer
    )
  }
}

extension ProtobufCodeGenParser {
  fileprivate func codeDependencies(
    file: FileDescriptor
  ) -> [Dependency] {
    var codeDependencies: [Dependency] = [
      Dependency(module: "GRPCProtobuf", accessLevel: .internal),
    ]

    // If any services in the file depend on well-known Protobuf types then also import
    // SwiftProtobuf. Importing SwiftProtobuf unconditionally results in warnings in the generated
    // code if access-levels are used on imports and no well-known types are used.
    let usesAnyWellKnownTypesInServices = file.services.contains { service in
      service.methods.contains { method in
        let inputIsWellKnown = method.inputType.wellKnownType != nil
        let outputIsWellKnown = method.outputType.wellKnownType != nil
        return inputIsWellKnown || outputIsWellKnown
      }
    }
    if usesAnyWellKnownTypesInServices {
      codeDependencies.append(Dependency(module: "SwiftProtobuf", accessLevel: self.accessLevel))
    }

    // Adding as dependencies the modules containing generated code or types for
    // '.proto' files imported in the '.proto' file we are parsing.
    codeDependencies.append(
      contentsOf: (self.protoToModuleMappings.neededModules(forFile: file) ?? []).map {
        Dependency(module: $0, accessLevel: self.accessLevel)
      }
    )
    // Adding extra imports passed in as an option to the plugin.
    codeDependencies.append(
      contentsOf: self.extraModuleImports.sorted().map {
        Dependency(module: $0, accessLevel: self.accessLevel)
      }
    )
    return codeDependencies
  }
}

extension GRPCCodeGen.ServiceDescriptor {
  fileprivate init(
    descriptor: SwiftProtobufPluginLibrary.ServiceDescriptor,
    package: String,
    protobufNamer: SwiftProtobufNamer,
    file: FileDescriptor
  ) {
    let methods = descriptor.methods.map {
      GRPCCodeGen.MethodDescriptor(
        descriptor: $0,
        protobufNamer: protobufNamer
      )
    }
    let name = Name(
      base: descriptor.name,
      // The service name from the '.proto' file is expected to be in upper camel case
      generatedUpperCase: descriptor.name,
      generatedLowerCase: CamelCaser.toLowerCamelCase(descriptor.name)
    )

    // Packages that are based on the path of the '.proto' file usually
    // contain dots. For example: "grpc.test".
    let namespace = Name(
      base: package,
      generatedUpperCase: protobufNamer.formattedUpperCasePackage(file: file),
      generatedLowerCase: protobufNamer.formattedLowerCasePackage(file: file)
    )
    let documentation = descriptor.protoSourceComments()
    self.init(documentation: documentation, name: name, namespace: namespace, methods: methods)
  }
}

extension GRPCCodeGen.MethodDescriptor {
  fileprivate init(
    descriptor: SwiftProtobufPluginLibrary.MethodDescriptor,
    protobufNamer: SwiftProtobufNamer
  ) {
    let name = Name(
      base: descriptor.name,
      // The method name from the '.proto' file is expected to be in upper camel case
      generatedUpperCase: descriptor.name,
      generatedLowerCase: CamelCaser.toLowerCamelCase(descriptor.name)
    )
    let documentation = descriptor.protoSourceComments()
    self.init(
      documentation: documentation,
      name: name,
      isInputStreaming: descriptor.clientStreaming,
      isOutputStreaming: descriptor.serverStreaming,
      inputType: protobufNamer.fullName(message: descriptor.inputType),
      outputType: protobufNamer.fullName(message: descriptor.outputType)
    )
  }
}

extension FileDescriptor {
  fileprivate var header: String {
    var header = String()
    // Field number used to collect the syntax field which is usually the first
    // declaration in a.proto file.
    // See more here:
    // https://github.com/apple/swift-protobuf/blob/main/Protos/SwiftProtobuf/google/protobuf/descriptor.proto
    let syntaxPath = IndexPath(index: 12)
    if let syntaxLocation = self.sourceCodeInfoLocation(path: syntaxPath) {
      header = syntaxLocation.asSourceComment(
        commentPrefix: "///",
        leadingDetachedPrefix: "//"
      )
    }
    return header
  }
}

extension SwiftProtobufNamer {
  internal func formattedUpperCasePackage(file: FileDescriptor) -> String {
    let unformattedPackage = self.typePrefix(forFile: file)
    return unformattedPackage.trimTrailingUnderscores()
  }

  internal func formattedLowerCasePackage(file: FileDescriptor) -> String {
    let upperCasePackage = self.formattedUpperCasePackage(file: file)
    let lowerCaseComponents = upperCasePackage.split(separator: "_").map { component in
      NamingUtils.toLowerCamelCase(String(component))
    }
    return lowerCaseComponents.joined(separator: "_")
  }
}

extension String {
  internal func trimTrailingUnderscores() -> String {
    if let index = self.lastIndex(where: { $0 != "_" }) {
      return String(self[...index])
    } else {
      return ""
    }
  }
}
