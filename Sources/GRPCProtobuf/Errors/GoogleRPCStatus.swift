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

public import GRPCCore
internal import SwiftProtobuf

/// An error containing structured details which can be delivered to the client.
///
/// This error follows the "richer error model" detailed in the
/// [gRPC error guide](https://grpc.io/docs/guides/error/) and
/// [Google AIP-193](https://google.aip.dev/193).
///
/// Like an `RPCError`, this error has a `code` and `message`. However it also includes
/// a list of structured error details which can be propagated to clients. A set of standard
/// details are provided by ``ErrorDetails``.
///
/// As a client you can extract this error from an `RPCError` using `unpackGoogleRPCStatus()`.
///
/// > Implementation details:
/// >
/// > The error information is transmitted to clients in the trailing metadata of an RPC. It is
/// > inserted into the metadata keyed by "grpc-status-details-bin". The value of the metadata is
/// > the serialized bytes of a "google.protobuf.Any" protocol buffers message. The content of which
/// > is a "google.rpc.Status" protocol buffers message containing the status code, message, and
/// > details.
public struct GoogleRPCStatus: Error {
  /// A code representing the high-level domain of the error.
  public var code: RPCError.Code

  /// A developer-facing error message, which should be in English.
  ///
  /// Any user-facing error message should be localized and sent in the `details` field
  /// or localized by the client.
  public var message: String

  /// A list of messages that carry the error details.
  public var details: [ErrorDetails]

  /// Create a new Google RPC Status error.
  ///
  /// - Parameters:
  ///   - code: A code representing the high-level domain of the error.
  ///   - message: A developer-facing error message.
  ///   - details: A list of messages that carry the error details.
  public init(code: RPCError.Code, message: String, details: [ErrorDetails]) {
    self.code = code
    self.message = message
    self.details = details
  }

  /// Create a new Google RPC Status error.
  ///
  /// - Parameters:
  ///   - code: A code representing the high-level domain of the error.
  ///   - message: A developer-facing error message.
  ///   - details: A list of messages that carry the error details.
  public init(code: RPCError.Code, message: String, details: ErrorDetails...) {
    self.code = code
    self.message = message
    self.details = details
  }
}

extension GoogleRPCStatus: GoogleProtobufAnyPackable {
  // See https://protobuf.dev/programming-guides/proto3/#any
  internal static var typeURL: String { "type.googleapis.com/google.rpc.Status" }

  init?(unpacking any: Google_Protobuf_Any) throws {
    guard any.isA(Google_Rpc_Status.self) else { return nil }
    let status = try Google_Rpc_Status(serializedBytes: any.value)

    let statusCode = Status.Code(rawValue: Int(status.code))
    self.code = statusCode.flatMap { RPCError.Code($0) } ?? .unknown
    self.message = status.message
    self.details = try status.details.map { try ErrorDetails(unpacking: $0) }
  }

  func pack() throws -> Google_Protobuf_Any {
    let status = try Google_Rpc_Status.with {
      $0.code = Int32(self.code.rawValue)
      $0.message = self.message
      $0.details = try self.details.map { try $0.pack() }
    }

    return try .with {
      $0.typeURL = Self.typeURL
      $0.value = try status.serializedBytes()
    }
  }
}

extension GoogleRPCStatus: RPCErrorConvertible {
  public var rpcErrorCode: RPCError.Code { self.code }
  public var rpcErrorMessage: String { self.message }
  public var rpcErrorMetadata: Metadata {
    do {
      let any = try self.pack()
      let bytes: [UInt8] = try any.serializedBytes()
      return [Metadata.statusDetailsBinKey: .binary(bytes)]
    } catch {
      // Failed to serialize error details. Not a lot can be done here.
      return [:]
    }
  }
}
