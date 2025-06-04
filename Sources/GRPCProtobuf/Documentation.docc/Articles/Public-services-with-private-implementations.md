# Public services with private implementations

Learn how to create a `public` gRPC service with private implementation details.

## Overview

It's not uncommon for a library to provide a gRPC service as part of its API.
For example, the gRPC Swift Extras package provides implementations of the gRPC
health and reflection services. Making the implementation of a service `public`
would require its generated gRPC and message types to also be `public`. This is
undesirable as it leaks implementation details into the public API of the
package. This article explains how to keep the generated types private while
making the service available as part of the public API.

## Hiding the implementation

You can hide the implementation details of your service by providing a wrapper
type conforming to `RegistrableRPCService`. This is the protocol used by
`GRPCServer` to register service methods with the server's router. Implementing
`RegistrableRPCService` is straightforward and can delegate to the underlying
service. This is demonstrated in the following code:

```swift
public struct GreeterService: RegistrableRPCService {
  private var base: Greeter

  public init() {
    self.base = Greeter()
  }

  public func registerMethods<Transport>(
    with router: inout RPCRouter<Transport>
  ) where Transport: ServerTransport {
    self.base.registerMethods(with: &router)
  }
}
```

In this example `Greeter` implements the underlying service and would conform to
the generated service protocol but would have a non-public access level.
`GreeterService` is a public wrapper type conforming to `RegistrableRPCService`
which implements its only requirement, `registerMethods(with:)`, by calling
through to the underlying implementation. The result is a service which can be
registered with a server where none of the generated types are part of the
public API.
