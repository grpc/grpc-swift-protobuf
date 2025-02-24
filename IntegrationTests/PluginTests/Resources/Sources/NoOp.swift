/*
 * Copyright 2025, gRPC Authors All rights reserved.
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
import GRPCProtobuf
import SwiftProtobuf

@main
struct PluginAdopter {
  static func main() async throws {
  }
}

struct NoOp: Noop_NoOpService.SimpleServiceProtocol {
  func noOp(
    request: Google_Protobuf_Empty,
    context: ServerContext
  ) async throws -> Google_Protobuf_Empty {
    return Google_Protobuf_Empty()
  }
}

struct NoOp2: Noop2_NoOpService.SimpleServiceProtocol {
  func noOp(
    request: Google_Protobuf_Empty,
    context: ServerContext
  ) async throws -> Google_Protobuf_Empty {
    return Google_Protobuf_Empty()
  }
}
