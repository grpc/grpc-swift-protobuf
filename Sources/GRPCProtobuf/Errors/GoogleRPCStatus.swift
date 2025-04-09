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
public import SwiftProtobuf

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

extension GoogleRPCStatus {
  /// Creates a new message by decoding the given `SwiftProtobufContiguousBytes` value
  /// containing a serialized message in Protocol Buffer binary format.
  ///
  /// - Parameters:
  ///   - serializedBytes: The binary-encoded message data to decode.
  ///   - extensions: An `ExtensionMap` used to look up and decode any
  ///     extensions in this message or messages nested within this message's
  ///     fields.
  ///   - partial: If `false` (the default), this method will check if the `Message`
  ///      is initialized after decoding to verify that all required fields are present.
  ///      If any are missing, this method throws `BinaryDecodingError`.
  ///   - options: The `BinaryDecodingOptions` to use.
  /// - Throws: `BinaryDecodingError` if decoding fails.
  public init<Bytes: SwiftProtobufContiguousBytes>(
    serializedBytes bytes: Bytes,
    extensions: (any ExtensionMap)? = nil,
    partial: Bool = false,
    options: BinaryDecodingOptions = BinaryDecodingOptions()
  ) throws {
    let status = try Google_Rpc_Status(
      serializedBytes: bytes,
      extensions: extensions,
      partial: partial,
      options: options
    )

    let statusCode = Status.Code(rawValue: Int(status.code))
    self.code = statusCode.flatMap { RPCError.Code($0) } ?? .unknown
    self.message = status.message
    self.details = try status.details.map { try ErrorDetails(unpacking: $0) }
  }

  /// Returns a `SwiftProtobufContiguousBytes` instance containing the Protocol Buffer binary
  /// format serialization of the message.
  ///
  /// - Parameters:
  ///   - partial: If `false` (the default), this method will check
  ///     `Message.isInitialized` before encoding to verify that all required
  ///     fields are present. If any are missing, this method throws.
  ///     `BinaryEncodingError/missingRequiredFields`.
  ///   - options: The `BinaryEncodingOptions` to use.
  /// - Returns: A `SwiftProtobufContiguousBytes` instance containing the binary serialization
  /// of the message.
  ///
  /// - Throws: `SwiftProtobufError` or `BinaryEncodingError` if encoding fails.
  public func serializedBytes<Bytes: SwiftProtobufContiguousBytes>(
    partial: Bool = false,
    options: BinaryEncodingOptions = BinaryEncodingOptions()
  ) throws -> Bytes {
    let status = try Google_Rpc_Status.with {
      $0.code = Int32(self.code.rawValue)
      $0.message = self.message
      $0.details = try self.details.map { try $0.pack() }
    }

    return try status.serializedBytes(partial: partial, options: options)
  }
}

extension GoogleRPCStatus: RPCErrorConvertible {
  public var rpcErrorCode: RPCError.Code { self.code }
  public var rpcErrorMessage: String { self.message }
  public var rpcErrorMetadata: Metadata {
    do {
      let bytes: [UInt8] = try self.serializedBytes()
      return [Metadata.statusDetailsBinKey: .binary(bytes)]
    } catch {
      // Failed to serialize error details. Not a lot can be done here.
      return [:]
    }
  }
}
