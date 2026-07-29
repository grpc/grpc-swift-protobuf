# Public services with private implementations

Learn how to create a `public` gRPC service with private implementation details.

## Overview

It's not uncommon for a library to provide a gRPC service as part of its API.
For example, the gRPC Swift Extras package provides implementations of the gRPC
health and reflection services. Making the implementation of a service `public`
requires its generated gRPC and message types to also be `public`. This is
undesirable as it leaks implementation details into the public API of the
package. This article explains how to keep the generated types private while
making the service available as part of the public API.

## Hiding the implementation

You can hide the implementation details of your service by providing a wrapper
type conforming to `RegistrableRPCService`. `GRPCServer` uses this protocol to
register service methods with the server's router. Implementing
`RegistrableRPCService` is straightforward: you can delegate to the underlying
service. The following code demonstrates this:

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

In this example, `Greeter` implements the underlying service and conforms to
the generated service protocol, but has a non-public access level.
`GreeterService` is a public wrapper type that conforms to `RegistrableRPCService`
and implements its only requirement, `registerMethods(with:)`, by calling
through to the underlying implementation. The result is a service that you can
register with a server, where none of the generated types are part of the
public API.
