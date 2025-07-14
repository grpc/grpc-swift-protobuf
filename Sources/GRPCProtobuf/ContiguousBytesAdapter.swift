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

public import GRPCCore  // internal but @usableFromInline
public import SwiftProtobuf  // internal but @usableFromInline

/// Brides between `GRPCContiguousBytes` and `SwiftProtobufContiguousBytes` which have the same
/// requirements.
///
/// This is necessary as `SwiftProtobufContiguousBytes` can't be the protocol in the gRPC API (as
/// it'd require a dependency on Protobuf in the core package), and `GRPCContiguousBytes` can't
/// refine `SwiftProtobufContiguousBytes` for the same reason.
@usableFromInline
@available(gRPCSwiftProtobuf 2.0, *)
struct ContiguousBytesAdapter<
  Bytes: GRPCContiguousBytes
>: GRPCContiguousBytes, SwiftProtobufContiguousBytes {
  @usableFromInline
  var bytes: Bytes

  @inlinable
  init(_ bytes: Bytes) {
    self.bytes = bytes
  }

  @inlinable
  init(repeating: UInt8, count: Int) {
    self.bytes = Bytes(repeating: repeating, count: count)
  }

  @inlinable
  init(_ sequence: some Sequence<UInt8>) {
    self.bytes = Bytes(sequence)
  }

  @inlinable
  var count: Int {
    self.bytes.count
  }

  @inlinable
  func withUnsafeBytes<R>(_ body: (UnsafeRawBufferPointer) throws -> R) rethrows -> R {
    try self.bytes.withUnsafeBytes(body)
  }

  @inlinable
  mutating func withUnsafeMutableBytes<R>(
    _ body: (UnsafeMutableRawBufferPointer) throws -> R
  ) rethrows -> R {
    try self.bytes.withUnsafeMutableBytes(body)
  }
}

@available(gRPCSwiftProtobuf 2.1, *)
extension ContiguousBytesAdapter: Sendable where Bytes: Sendable {}
