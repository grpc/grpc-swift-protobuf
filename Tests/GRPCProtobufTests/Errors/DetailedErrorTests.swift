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
import SwiftProtobuf
import Testing

struct DetailedErrorTests {
  @Test(
    "Google RPC Status is transferred over the wire",
    arguments: [
      ([], []),
      (["ErrorInfo"], [.errorInfo(.testValue)]),
      (["RetryInfo"], [.retryInfo(.testValue)]),
      (["DebugInfo"], [.debugInfo(.testValue)]),
      (["QuotaFailure"], [.quotaFailure(.testValue)]),
      (["PreconditionFailure"], [.preconditionFailure(.testValue)]),
      (["BadRequest"], [.badRequest(.testValue)]),
      (["RequestInfo"], [.requestInfo(.testValue)]),
      (["ResourceInfo"], [.resourceInfo(.testValue)]),
      (["Help"], [.help(.testValue)]),
      (["LocalizedMessage"], [.localizedMessage(.testValue)]),
      (["DebugInfo", "RetryInfo"], [.debugInfo(.testValue), .retryInfo(.testValue)]),
      (["Help", "PreconditionFailure"], [.help(.testValue), .preconditionFailure(.testValue)]),
      (["Help", "Help", "Help"], [.help(.testValue), .help(.testValue), .help(.testValue)]),
    ] as [([String], [ErrorDetails])]
  )
  @available(gRPCSwiftProtobuf 1.0, *)
  func rpcStatus(details: [String], expected: [ErrorDetails]) async throws {
    let inProcess = InProcessTransport()
    try await withGRPCServer(transport: inProcess.server, services: [ErrorThrowingService()]) { _ in
      try await withGRPCClient(transport: inProcess.client) { client in
        let errorClient = ErrorService.Client(wrapping: client)
        let subkinds = details.joined(separator: ",")
        let kind = "status/\(subkinds)"

        await #expect {
          try await errorClient.throwError(.with { $0.kind = kind })
        } throws: { error in
          guard let rpcError = error as? RPCError else { return false }
          guard let status = try? rpcError.unpackGoogleRPCStatus() else { return false }

          // Code/message should be the same.
          #expect(status.code == rpcError.code)
          #expect(status.message == rpcError.message)

          // Set by the service.
          #expect(status.code == .unknown)
          #expect(status.message == subkinds)
          #expect(status.details == expected)

          return true
        }
      }
    }
  }

  @Test(
    arguments: [
      (.errorInfo(.testValue), #"ErrorInfo(reason: "r", domain: "d", metadata: ["k": "v"])"#),
      (.retryInfo(.testValue), #"RetryInfo(delay: 1.0 seconds)"#),
      (.debugInfo(.testValue), #"DebugInfo(stack: ["foo.foo()", "foo.bar()"], detail: "detail")"#),
      (
        .quotaFailure(.testValue),
        #"QuotaFailure(violations: [Violation(subject: "s", violationDescription: "d")])"#
      ),
      (
        .preconditionFailure(.testValue),
        #"PreconditionFailure(violations: [Violation(subject: "s", type: "t", violationDescription: "d")])"#
      ),
      (
        .badRequest(.testValue),
        #"BadRequest(violations: [FieldViolation(field: "f", violationDescription: "d")])"#
      ),
      (.requestInfo(.testValue), #"RequestInfo(requestID: "id", servingData: "d")"#),
      (
        .resourceInfo(.testValue),
        #"ResourceInfo(name: "n", owner: "", type: "t", errorDescription: "d")"#
      ),
      (.help(.testValue), #"Help(links: [Link(url: "url", linkDescription: "d")])"#),
      (.localizedMessage(.testValue), #"LocalizedMessage(locale: "l", message: "m")"#),
    ] as [(ErrorDetails, String)]
  )
  @available(gRPCSwiftProtobuf 1.0, *)
  func errorInfoDescription(_ details: ErrorDetails, expected: String) {
    #expect(String(describing: details) == expected)
  }

  @Test("Round-trip encoding of GoogleRPCStatus")
  @available(gRPCSwiftProtobuf 1.0, *)
  func googleRPCStatusRoundTripCoding() throws {
    let detail = ErrorDetails.BadRequest(violations: [.init(field: "foo", description: "bar")])
    let status = GoogleRPCStatus(code: .dataLoss, message: "Uh oh", details: [.badRequest(detail)])

    let serialized: [UInt8] = try status.serializedBytes()
    let deserialized = try GoogleRPCStatus(serializedBytes: serialized)
    #expect(deserialized.code == status.code)
    #expect(deserialized.message == status.message)
    #expect(deserialized.details.count == status.details.count)
    #expect(deserialized.details.first?.badRequest == detail)
  }
}

@available(gRPCSwiftProtobuf 1.0, *)
private struct ErrorThrowingService: ErrorService.SimpleServiceProtocol {
  func throwError(
    request: ThrowInput,
    context: ServerContext
  ) async throws -> Google_Protobuf_Empty {
    if request.kind.starts(with: "status/") {
      try self.throwStatusError(kind: String(request.kind.dropFirst("status/".count)))
    } else {
      throw RPCError(code: .invalidArgument, message: "'\(request.kind)' is invalid.")
    }
  }

  private func throwStatusError(kind: String) throws(GoogleRPCStatus) -> Never {
    var details: [ErrorDetails] = []
    for subkind in kind.split(separator: ",") {
      if let detail = self.errorDetails(kind: String(subkind)) {
        details.append(detail)
      } else {
        throw GoogleRPCStatus(
          code: .invalidArgument,
          message: "Unknown error subkind",
          details: [
            .badRequest(
              violations: [
                ErrorDetails.BadRequest.FieldViolation(
                  field: "kind",
                  description: "'\(kind)' is invalid"
                )
              ]
            )
          ]
        )
      }
    }

    throw GoogleRPCStatus(code: .unknown, message: kind, details: details)
  }

  private func errorDetails(kind: String) -> ErrorDetails? {
    let details: ErrorDetails?

    switch kind {
    case "ErrorInfo":
      details = .errorInfo(.testValue)
    case "RetryInfo":
      details = .retryInfo(.testValue)
    case "DebugInfo":
      details = .debugInfo(.testValue)
    case "QuotaFailure":
      details = .quotaFailure(.testValue)
    case "PreconditionFailure":
      details = .preconditionFailure(.testValue)
    case "BadRequest":
      details = .badRequest(.testValue)
    case "RequestInfo":
      details = .requestInfo(.testValue)
    case "ResourceInfo":
      details = .resourceInfo(.testValue)
    case "Help":
      details = .help(.testValue)
    case "LocalizedMessage":
      details = .localizedMessage(.testValue)
    default:
      details = nil
    }

    return details
  }
}

@available(gRPCSwiftProtobuf 1.0, *)
extension ErrorDetails.ErrorInfo {
  fileprivate static let testValue = Self(reason: "r", domain: "d", metadata: ["k": "v"])
}

@available(gRPCSwiftProtobuf 1.0, *)
extension ErrorDetails.RetryInfo {
  fileprivate static let testValue = Self(delay: .seconds(1))
}

@available(gRPCSwiftProtobuf 1.0, *)
extension ErrorDetails.DebugInfo {
  fileprivate static let testValue = Self(
    stack: ["foo.foo()", "foo.bar()"],
    detail: "detail"
  )
}

@available(gRPCSwiftProtobuf 1.0, *)
extension ErrorDetails.QuotaFailure {
  fileprivate static let testValue = Self(
    violations: [
      Violation(subject: "s", description: "d")
    ]
  )
}

@available(gRPCSwiftProtobuf 1.0, *)
extension ErrorDetails.PreconditionFailure {
  fileprivate static let testValue = Self(
    violations: [
      Violation(type: "t", subject: "s", description: "d")
    ]
  )
}

@available(gRPCSwiftProtobuf 1.0, *)
extension ErrorDetails.BadRequest {
  fileprivate static let testValue = Self(
    violations: [
      FieldViolation(field: "f", description: "d")
    ]
  )
}

@available(gRPCSwiftProtobuf 1.0, *)
extension ErrorDetails.RequestInfo {
  fileprivate static let testValue = Self(requestID: "id", servingData: "d")
}

@available(gRPCSwiftProtobuf 1.0, *)
extension ErrorDetails.ResourceInfo {
  fileprivate static let testValue = Self(type: "t", name: "n", errorDescription: "d")
}

@available(gRPCSwiftProtobuf 1.0, *)
extension ErrorDetails.Help {
  fileprivate static let testValue = Self(
    links: [
      Link(url: "url", description: "d")
    ]
  )
}

@available(gRPCSwiftProtobuf 1.0, *)
extension ErrorDetails.LocalizedMessage {
  fileprivate static let testValue = Self(locale: "l", message: "m")
}
