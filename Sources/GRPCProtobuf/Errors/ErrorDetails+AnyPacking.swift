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

internal import SwiftProtobuf

/// A type which can be packed and unpacked from a `Google_Protobuf_Any` message.
internal protocol GoogleProtobufAnyPackable {
  static var typeURL: String { get }

  /// Pack the value into a `Google_Protobuf_Any`, if possible.
  func pack() throws -> Google_Protobuf_Any

  /// Unpack the value from a `Google_Protobuf_Any`, if possible.
  init?(unpacking any: Google_Protobuf_Any) throws
}

/// A type which is backed by a Protobuf message.
///
/// This is a convenience protocol to allow for automatic packing/unpacking of messages
/// where possible.
internal protocol ProtobufBacked {
  associatedtype Message: SwiftProtobuf.Message
  var storage: Message { get set }
  init(storage: Message)
}

extension GoogleProtobufAnyPackable where Self: ProtobufBacked {
  func pack() throws -> Google_Protobuf_Any {
    try .with {
      $0.typeURL = Self.typeURL
      $0.value = try self.storage.serializedBytes()
    }
  }

  init?(unpacking any: Google_Protobuf_Any) throws {
    guard let storage = try any.unpack(Message.self) else { return nil }
    self.init(storage: storage)
  }
}

extension Google_Protobuf_Any {
  func unpack<Unpacked: Message>(_ as: Unpacked.Type) throws -> Unpacked? {
    if self.isA(Unpacked.self) {
      return try Unpacked(serializedBytes: self.value)
    } else {
      return nil
    }
  }
}

@available(gRPCSwiftProtobuf 1.0, *)
extension ErrorDetails {
  // Note: this type isn't packable into an 'Any' protobuf so doesn't conform
  // to 'GoogleProtobufAnyPackable' despite holding types which are packable.

  func pack() throws -> Google_Protobuf_Any {
    switch self.wrapped {
    case .errorInfo(let info):
      return try info.pack()
    case .retryInfo(let info):
      return try info.pack()
    case .debugInfo(let info):
      return try info.pack()
    case .quotaFailure(let info):
      return try info.pack()
    case .preconditionFailure(let info):
      return try info.pack()
    case .badRequest(let info):
      return try info.pack()
    case .requestInfo(let info):
      return try info.pack()
    case .resourceInfo(let info):
      return try info.pack()
    case .help(let info):
      return try info.pack()
    case .localizedMessage(let info):
      return try info.pack()
    case .any(let any):
      return any
    }
  }

  init(unpacking any: Google_Protobuf_Any) throws {
    if let unpacked = try Self.unpack(any: any) {
      self = unpacked
    } else {
      self = .any(any)
    }
  }

  private static func unpack(any: Google_Protobuf_Any) throws -> Self? {
    switch any.typeURL {
    case ErrorInfo.typeURL:
      if let unpacked = try ErrorInfo(unpacking: any) {
        return .errorInfo(unpacked)
      }
    case RetryInfo.typeURL:
      if let unpacked = try RetryInfo(unpacking: any) {
        return .retryInfo(unpacked)
      }
    case DebugInfo.typeURL:
      if let unpacked = try DebugInfo(unpacking: any) {
        return .debugInfo(unpacked)
      }
    case QuotaFailure.typeURL:
      if let unpacked = try QuotaFailure(unpacking: any) {
        return .quotaFailure(unpacked)
      }
    case PreconditionFailure.typeURL:
      if let unpacked = try PreconditionFailure(unpacking: any) {
        return .preconditionFailure(unpacked)
      }
    case BadRequest.typeURL:
      if let unpacked = try BadRequest(unpacking: any) {
        return .badRequest(unpacked)
      }
    case RequestInfo.typeURL:
      if let unpacked = try RequestInfo(unpacking: any) {
        return .requestInfo(unpacked)
      }
    case ResourceInfo.typeURL:
      if let unpacked = try ResourceInfo(unpacking: any) {
        return .resourceInfo(unpacked)
      }
    case Help.typeURL:
      if let unpacked = try Help(unpacking: any) {
        return .help(unpacked)
      }
    case LocalizedMessage.typeURL:
      if let unpacked = try LocalizedMessage(unpacking: any) {
        return .localizedMessage(unpacked)
      }
    default:
      return .any(any)
    }

    return nil
  }
}
