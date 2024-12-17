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

extension Metadata {
  static let statusDetailsBinKey = "grpc-status-details-bin"
}

extension RPCError {
  /// Unpack a ``GoogleRPCStatus`` error from the error metadata.
  ///
  /// - Throws: If status details exist in the metadata but they couldn't be unpacked to
  ///     a ``GoogleRPCStatus``.
  /// - Returns: The unpacked ``GoogleRPCStatus`` or `nil` if the metadata didn't contain any
  ///     status details.
  public func unpackGoogleRPCStatus() throws -> GoogleRPCStatus? {
    let values = self.metadata[binaryValues: Metadata.statusDetailsBinKey]
    guard let bytes = values.first(where: { _ in true }) else { return nil }

    let any = try Google_Protobuf_Any(serializedBytes: bytes)
    return try GoogleRPCStatus(unpacking: any)
  }
}
