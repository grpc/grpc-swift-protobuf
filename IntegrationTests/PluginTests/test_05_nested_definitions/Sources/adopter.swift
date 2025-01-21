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

import GRPCCore
import GRPCInProcessTransport
import GRPCProtobuf

@main
struct PluginAdopter {
  static func main() async throws {
    let inProcess = InProcessTransport()
    try await withGRPCServer(transport: inProcess.server, services: [Greeter()]) { server in
      try await withGRPCClient(transport: inProcess.client) { client in
        try await Self.doRPC(Helloworld_Greeter.Client(wrapping: client))
      }
    }

    try await withGRPCServer(transport: inProcess.server, services: [FooService1()]) { server in
      try await withGRPCClient(transport: inProcess.client) { client in
        try await Self.doRPC(Foo_FooService1.Client(wrapping: client))
      }
    }
  }

  static func doRPC(_ greeter: Helloworld_Greeter.Client) async throws {
    do {
      let reply = try await greeter.sayHello(.with { $0.name = "(ignored)" })
      print("Reply: \(reply.message)")
    } catch {
      print("Error: \(error)")
    }
  }

  static func doRPC(_ fooService1: Foo_FooService1.Client) async throws {
    do {
      let reply = try await fooService1.foo(.with { _ in () })
      print("Reply: \(reply.hashValue)")
    } catch {
      print("Error: \(error)")
    }
  }
}

struct Greeter: Helloworld_Greeter.SimpleServiceProtocol {
  func sayHello(
    request: Helloworld_HelloRequest,
    context: ServerContext
  ) async throws -> Helloworld_HelloReply {
    return .with { reply in
      reply.message = "Hello, world!"
    }
  }
}

struct FooService1: Foo_FooService1.SimpleServiceProtocol {
  func foo(request: Foo_FooInput, context: GRPCCore.ServerContext) async throws -> Foo_FooOutput {
    return .with { _ in
      ()
    }
  }
}
