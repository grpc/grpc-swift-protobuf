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

@available(gRPCSwiftProtobuf 2.0, *)
extension ErrorDetails: CustomStringConvertible {
  public var description: String {
    switch self.wrapped {
    case .errorInfo(let info):
      return String(describing: info)
    case .retryInfo(let info):
      return String(describing: info)
    case .debugInfo(let info):
      return String(describing: info)
    case .quotaFailure(let info):
      return String(describing: info)
    case .preconditionFailure(let info):
      return String(describing: info)
    case .badRequest(let info):
      return String(describing: info)
    case .requestInfo(let info):
      return String(describing: info)
    case .resourceInfo(let info):
      return String(describing: info)
    case .help(let info):
      return String(describing: info)
    case .localizedMessage(let info):
      return String(describing: info)
    case .any(let any):
      return String(describing: any)
    }
  }
}

// Some errors use protobuf messages as their storage so the default description isn't
// representative

@available(gRPCSwiftProtobuf 2.0, *)
extension ErrorDetails.ErrorInfo: CustomStringConvertible {
  public var description: String {
    "\(Self.self)(reason: \"\(self.reason)\", domain: \"\(self.domain)\", metadata: \(self.metadata))"
  }
}

@available(gRPCSwiftProtobuf 2.0, *)
extension ErrorDetails.DebugInfo: CustomStringConvertible {
  public var description: String {
    "\(Self.self)(stack: \(self.stack), detail: \"\(self.detail)\")"
  }
}

@available(gRPCSwiftProtobuf 2.0, *)
extension ErrorDetails.QuotaFailure.Violation: CustomStringConvertible {
  public var description: String {
    "\(Self.self)(subject: \"\(self.subject)\", violationDescription: \"\(self.violationDescription)\")"
  }
}

@available(gRPCSwiftProtobuf 2.0, *)
extension ErrorDetails.PreconditionFailure.Violation: CustomStringConvertible {
  public var description: String {
    "\(Self.self)(subject: \"\(self.subject)\", type: \"\(self.type)\", violationDescription: \"\(self.violationDescription)\")"
  }
}

@available(gRPCSwiftProtobuf 2.0, *)
extension ErrorDetails.BadRequest.FieldViolation: CustomStringConvertible {
  public var description: String {
    "\(Self.self)(field: \"\(self.field)\", violationDescription: \"\(self.violationDescription)\")"
  }
}

@available(gRPCSwiftProtobuf 2.0, *)
extension ErrorDetails.RequestInfo: CustomStringConvertible {
  public var description: String {
    "\(Self.self)(requestID: \"\(self.requestID)\", servingData: \"\(self.servingData)\")"
  }
}

@available(gRPCSwiftProtobuf 2.0, *)
extension ErrorDetails.ResourceInfo: CustomStringConvertible {
  public var description: String {
    "\(Self.self)(name: \"\(self.name)\", owner: \"\(self.owner)\", type: \"\(self.type)\", errorDescription: \"\(self.errorDescription)\")"
  }
}

@available(gRPCSwiftProtobuf 2.0, *)
extension ErrorDetails.Help.Link: CustomStringConvertible {
  public var description: String {
    "\(Self.self)(url: \"\(self.url)\", linkDescription: \"\(self.linkDescription)\")"
  }
}

@available(gRPCSwiftProtobuf 2.0, *)
extension ErrorDetails.LocalizedMessage: CustomStringConvertible {
  public var description: String {
    "\(Self.self)(locale: \"\(self.locale)\", message: \"\(self.message)\")"
  }
}
