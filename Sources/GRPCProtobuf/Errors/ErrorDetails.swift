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

public import SwiftProtobuf

/// Common details which can be used to supplement ``DetailedRPCError`` and ``GoogleRPCStatus``.
///
/// This represents the set of common error types suggested by [Google AIP-193](https://google.aip.dev/193).
/// These types are derived from and will serialize to the those represented in
/// [google/rpc/error_details.proto](https://github.com/googleapis/googleapis/blob/3597f7db2191c00b100400991ef96e52d62f5841/google/rpc/error_details.proto).
///
/// This type also allows you to provide wrap your own error details up as an "Any"
/// protobuf (`Google_Protobuf_Any`).
public struct ErrorDetails: Sendable, Hashable {
  enum Wrapped: Sendable, Hashable {
    case errorInfo(ErrorInfo)
    case retryInfo(RetryInfo)
    case debugInfo(DebugInfo)
    case quotaFailure(QuotaFailure)
    case preconditionFailure(PreconditionFailure)
    case badRequest(BadRequest)
    case requestInfo(RequestInfo)
    case resourceInfo(ResourceInfo)
    case help(Help)
    case localizedMessage(LocalizedMessage)
    case any(Google_Protobuf_Any)
  }

  private(set) var wrapped: Wrapped

  private init(_ wrapped: Wrapped) {
    self.wrapped = wrapped
  }

  /// Create a new detail wrapping a `Google_Protobuf_Any`.
  public static func any(_ any: Google_Protobuf_Any) -> Self {
    Self(.any(any))
  }

  /// Create a new detail wrapping an ``ErrorInfo-swift.struct``.
  public static func errorInfo(_ info: ErrorInfo) -> Self {
    Self(.errorInfo(info))
  }

  /// Create a ``ErrorInfo-swift.struct`` detail.
  ///
  /// - Parameters:
  ///   - reason: The reason of the error.
  ///   - domain: The logical grouping to which the "reason" belongs.
  ///   - metadata: Additional structured details about this error.
  public static func errorInfo(
    reason: String,
    domain: String,
    metadata: [String: String] = [:]
  ) -> Self {
    Self.errorInfo(ErrorInfo(reason: reason, domain: domain, metadata: metadata))
  }

  /// Create a new detail wrapping a ``RetryInfo-swift.struct``.
  public static func retryInfo(_ info: RetryInfo) -> Self {
    Self(.retryInfo(info))
  }

  /// Create a ``RetryInfo-swift.struct`` detail.
  ///
  /// - Parameter delay: Amount of time clients should wait before retrying this request.
  public static func retryInfo(delay: Duration) -> Self {
    Self.retryInfo(RetryInfo(delay: delay))
  }

  /// Create a new detail wrapping a ``DebugInfo-swift.struct``.
  public static func debugInfo(_ info: DebugInfo) -> Self {
    Self(.debugInfo(info))
  }

  /// Create a ``DebugInfo-swift.struct`` detail.
  ///
  /// - Parameters:
  ///   - stack: The stack trace entries indicating where the error occurred.
  ///   - detail: Additional debugging information provided by the server.
  public static func debugInfo(stack: [String], detail: String) -> Self {
    Self.debugInfo(DebugInfo(stack: stack, detail: detail))
  }

  /// Create a new detail wrapping a ``QuotaFailure-swift.struct``.
  public static func quotaFailure(_ info: QuotaFailure) -> Self {
    Self(.quotaFailure(info))
  }

  /// Create a ``QuotaFailure-swift.struct`` detail.
  ///
  /// - Parameter violations: Describes all quota violations.
  public static func quotaFailure(violations: [QuotaFailure.Violation]) -> Self {
    Self.quotaFailure(QuotaFailure(violations: violations))
  }

  /// Create a new detail wrapping a ``PreconditionFailure-swift.struct``.
  public static func preconditionFailure(_ info: PreconditionFailure) -> Self {
    Self(.preconditionFailure(info))
  }

  /// Create a ``PreconditionFailure-swift.struct`` detail.
  ///
  /// - Parameter violations: Describes all precondition violations.
  public static func preconditionFailure(violations: [PreconditionFailure.Violation]) -> Self {
    Self.preconditionFailure(PreconditionFailure(violations: violations))
  }

  /// Create a new detail wrapping a ``BadRequest-swift.struct``.
  public static func badRequest(_ info: BadRequest) -> Self {
    Self(.badRequest(info))
  }

  /// Create a ``BadRequest-swift.struct`` detail.
  ///
  /// - Parameter violations: Describes all request violations.
  public static func badRequest(violations: [BadRequest.FieldViolation]) -> Self {
    Self.badRequest(BadRequest(violations: violations))
  }

  /// Create a new detail wrapping a ``RequestInfo-swift.struct``.
  public static func requestInfo(_ info: RequestInfo) -> Self {
    Self(.requestInfo(info))
  }

  /// Create a ``RequestInfo-swift.struct`` detail.
  ///
  /// - Parameters:
  ///   - requestID: /// An opaque string that should only be interpreted by the service generating
  ///       it. For example, it can be used to identify requests in the service's logs.
  ///   - servingData: Any data that was used to serve this request. For example, an encrypted
  ///       stack trace that can be sent back to the service provider for debugging.
  public static func requestInfo(requestID: String, servingData: String) -> Self {
    Self.requestInfo(RequestInfo(requestID: requestID, servingData: servingData))
  }

  /// Create a new detail wrapping a ``ResourceInfo-swift.struct``.
  public static func resourceInfo(_ info: ResourceInfo) -> Self {
    Self(.resourceInfo(info))
  }

  ///  Create a ``ResourceInfo-swift.struct`` detail.
  ///
  /// - Parameters:
  ///   - type: The type of resource being accessed, e,.g. "sql table", "file" or type URL of the
  ///       resource.
  ///   - name: The name of the resource being accessed.
  ///   - errorDescription: Describes the error encountered when accessing this resource.
  ///   - owner: The owner of the resource.
  public static func resourceInfo(
    type: String,
    name: String,
    errorDescription: String,
    owner: String = ""
  ) -> Self {
    Self.resourceInfo(
      ResourceInfo(type: type, name: name, errorDescription: errorDescription, owner: owner)
    )
  }

  /// Create a ``Help-swift.struct`` detail.
  public static func help(_ info: Help) -> Self {
    Self(.help(info))
  }

  ///  Create a ``Help-swift.struct`` detail.
  ///
  /// - Parameter links: URL(s) pointing to additional information on handling the current error.
  public static func help(links: [Help.Link]) -> Self {
    Self.help(Help(links: links))
  }

  /// Create a ``LocalizedMessage-swift.struct`` detail.
  public static func localizedMessage(_ info: LocalizedMessage) -> Self {
    Self(.localizedMessage(info))
  }

  /// Create a ``Help-swift.struct`` detail.
  ///
  /// - Parameters:
  ///   - locale: The locale used.
  ///   - message: Localized error message.
  public static func localizedMessage(locale: String, message: String) -> Self {
    Self.localizedMessage(LocalizedMessage(locale: locale, message: message))
  }
}

extension ErrorDetails {
  /// Returns error info if set.
  public var errorInfo: ErrorInfo? {
    switch self.wrapped {
    case .errorInfo(let info):
      return info
    default:
      return nil
    }
  }

  /// Returns retry info if set.
  public var retryInfo: RetryInfo? {
    switch self.wrapped {
    case .retryInfo(let info):
      return info
    default:
      return nil
    }
  }

  /// Returns debug info if set.
  public var debugInfo: DebugInfo? {
    switch self.wrapped {
    case .debugInfo(let info):
      return info
    default:
      return nil
    }
  }

  /// Returns a quota failure if set.
  public var quotaFailure: QuotaFailure? {
    switch self.wrapped {
    case .quotaFailure(let info):
      return info
    default:
      return nil
    }
  }

  /// Returns a precondition failure if set.
  public var preconditionFailure: PreconditionFailure? {
    switch self.wrapped {
    case .preconditionFailure(let info):
      return info
    default:
      return nil
    }
  }

  /// Returns bad request details if set.
  public var badRequest: BadRequest? {
    switch self.wrapped {
    case .badRequest(let info):
      return info
    default:
      return nil
    }
  }

  /// Returns request info if set.
  public var requestInfo: RequestInfo? {
    switch self.wrapped {
    case .requestInfo(let info):
      return info
    default:
      return nil
    }
  }

  /// Returns resource info if set.
  public var resourceInfo: ResourceInfo? {
    switch self.wrapped {
    case .resourceInfo(let info):
      return info
    default:
      return nil
    }
  }

  /// Returns help if set.
  public var help: Help? {
    switch self.wrapped {
    case .help(let info):
      return info
    default:
      return nil
    }
  }

  /// Returns a localized message if set.
  public var localizedMessage: LocalizedMessage? {
    switch self.wrapped {
    case .localizedMessage(let info):
      return info
    default:
      return nil
    }
  }

  /// Returns `Google_Protobuf_Any` if applicable.
  ///
  /// Calling this **doesn't** encode a detail of another type into a `Google_Protobuf_Any`.
  public var any: Google_Protobuf_Any? {
    switch self.wrapped {
    case .any(let any):
      return any
    default:
      return nil
    }
  }
}
