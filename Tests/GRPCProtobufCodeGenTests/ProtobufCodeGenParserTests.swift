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

import GRPCCodeGen
import GRPCProtobufCodeGen
import SwiftProtobuf
import SwiftProtobufPluginLibrary
import Testing

@Suite
struct ProtobufCodeGenParserTests {
  @Suite("Self-contained service (test-service.proto)")
  struct TestService: UsesDescriptorSet {
    static let descriptorSetName = "test-service"
    static let fileDescriptorName = "test-service"

    let codeGen: CodeGenerationRequest

    init() throws {
      let descriptor = try #require(try Self.fileDescriptor)
      self.codeGen = try parseDescriptor(descriptor)
    }

    @Test("Filename")
    func fileName() {
      #expect(self.codeGen.fileName == "test-service.proto")
    }

    @Test("Leading trivia")
    func leadingTrivia() {
      let expected = """
        /// Leading trivia.

        // DO NOT EDIT.
        // swift-format-ignore-file
        //
        // Generated by the gRPC Swift generator plugin for the protocol buffer compiler.
        // Source: test-service.proto
        //
        // For information on using the generated types, please see the documentation:
        //   https://github.com/grpc/grpc-swift

        """

      #expect(self.codeGen.leadingTrivia == expected)
    }

    @Test("Dependencies")
    func dependencies() {
      let expected: [GRPCCodeGen.Dependency] = [
        .init(module: "GRPCProtobuf", accessLevel: .internal)  // Always an internal import
      ]
      #expect(self.codeGen.dependencies == expected)
    }

    @Suite("Service")
    struct Service {
      let service: GRPCCodeGen.ServiceDescriptor

      init() throws {
        let request = try parseDescriptor(try #require(try TestService.fileDescriptor))
        try #require(request.services.count == 1)
        self.service = try #require(request.services.first)
      }

      @Test("Name")
      func name() {
        #expect(self.service.name.base == "TestService")
      }

      @Test("Namespace")
      func namespace() {
        #expect(self.service.namespace.base == "test")
      }

      @Suite("Methods")
      struct Methods {
        let unary: GRPCCodeGen.MethodDescriptor
        let clientStreaming: GRPCCodeGen.MethodDescriptor
        let serverStreaming: GRPCCodeGen.MethodDescriptor
        let bidiStreaming: GRPCCodeGen.MethodDescriptor

        init() throws {
          let request = try parseDescriptor(try #require(try TestService.fileDescriptor))
          #expect(request.services.count == 1)
          let service = try #require(request.services.first)

          self.unary = service.methods[0]
          self.clientStreaming = service.methods[1]
          self.serverStreaming = service.methods[2]
          self.bidiStreaming = service.methods[3]
        }

        @Test("Documentation")
        func documentation() {
          #expect(self.unary.documentation == "/// Unary docs.\n")
          #expect(self.clientStreaming.documentation == "/// Client streaming docs.\n")
          #expect(self.serverStreaming.documentation == "/// Server streaming docs.\n")
          #expect(self.bidiStreaming.documentation == "/// Bidirectional streaming docs.\n")
        }

        @Test("Name")
        func name() {
          #expect(self.unary.name.base == "Unary")
          #expect(self.clientStreaming.name.base == "ClientStreaming")
          #expect(self.serverStreaming.name.base == "ServerStreaming")
          #expect(self.bidiStreaming.name.base == "BidirectionalStreaming")
        }

        @Test("Input")
        func input() {
          #expect(self.unary.inputType == "Test_TestInput")
          #expect(!self.unary.isInputStreaming)

          #expect(self.clientStreaming.inputType == "Test_TestInput")
          #expect(self.clientStreaming.isInputStreaming)

          #expect(self.serverStreaming.inputType == "Test_TestInput")
          #expect(!self.serverStreaming.isInputStreaming)

          #expect(self.bidiStreaming.inputType == "Test_TestInput")
          #expect(self.bidiStreaming.isInputStreaming)
        }

        @Test("Output")
        func output() {
          #expect(self.unary.outputType == "Test_TestOutput")
          #expect(!self.unary.isOutputStreaming)

          #expect(self.clientStreaming.outputType == "Test_TestOutput")
          #expect(!self.clientStreaming.isOutputStreaming)

          #expect(self.serverStreaming.outputType == "Test_TestOutput")
          #expect(self.serverStreaming.isOutputStreaming)

          #expect(self.bidiStreaming.outputType == "Test_TestOutput")
          #expect(self.bidiStreaming.isOutputStreaming)
        }
      }
    }
  }

  @Suite("Multi-service file (foo-service.proto)")
  struct FooService: UsesDescriptorSet {
    static let descriptorSetName = "foo-service"
    static let fileDescriptorName = "foo-service"

    let codeGen: CodeGenerationRequest

    init() throws {
      let descriptor = try #require(try Self.fileDescriptor)
      self.codeGen = try parseDescriptor(descriptor)
    }

    @Test("Name")
    func name() {
      #expect(self.codeGen.fileName == "foo-service.proto")
    }

    @Test("Dependencies")
    func dependencies() {
      let expected: [GRPCCodeGen.Dependency] = [
        .init(module: "GRPCProtobuf", accessLevel: .internal)  // Always an internal import
      ]
      #expect(self.codeGen.dependencies == expected)
    }

    @Test("Service1")
    func service1() throws {
      let service = self.codeGen.services[0]
      #expect(service.name.base == "FooService1")
      #expect(service.namespace.base == "foo")
      #expect(service.methods.count == 1)
    }

    @Test("Service1.Method")
    func service1Method() throws {
      let method = self.codeGen.services[0].methods[0]
      #expect(method.name.base == "Foo")
      #expect(method.inputType == "Foo_FooInput")
      #expect(method.outputType == "Foo_FooOutput")
    }

    @Test("Service2")
    func service2() throws {
      let service = self.codeGen.services[1]
      #expect(service.name.base == "FooService2")
      #expect(service.namespace.base == "foo")
      #expect(service.methods.count == 1)
    }

    @Test("Service2.Method")
    func service2Method() throws {
      let method = self.codeGen.services[1].methods[0]
      #expect(method.name.base == "Foo")
      #expect(method.inputType == "Foo_FooInput")
      #expect(method.outputType == "Foo_FooOutput")
    }
  }

  @Suite("Service with no package (bar-service.proto)")
  struct BarService: UsesDescriptorSet {
    static var descriptorSetName: String { "bar-service" }
    static var fileDescriptorName: String { "bar-service" }

    let codeGen: CodeGenerationRequest
    let service: GRPCCodeGen.ServiceDescriptor

    init() throws {
      let descriptor = try #require(try Self.fileDescriptor)
      self.codeGen = try parseDescriptor(descriptor)
      self.service = try #require(self.codeGen.services.first)
    }

    @Test("Service name")
    func serviceName() {
      #expect(self.service.name.base == "BarService")
    }

    @Test("Service namespace")
    func serviceNamespace() {
      #expect(self.service.namespace.base == "")
    }
  }
}
