# Understanding the generated code

Understand what code `protoc-gen-grpc-swift-2` generates from a `.proto`
file and how to use it.

## Overview

The gRPC Swift Protobuf package provides a plugin to the Protocol Buffers
Compiler (`protoc`) called `protoc-gen-grpc-swift-2`. The plugin generates the
gRPC-specific code for services defined in a `.proto` file.

### Package namespace

Most `.proto` files contain a `package` directive near the start of the file
describing the namespace it belongs to. Here's an example:

```proto
package foo.bar.v1;
```

The package name "foo.bar.v1" is important because generated types use it as a
prefix. By default, the plugin replaces periods with underscores, capitalizes
each word, and adds a trailing underscore. For this package, the prefix is
"Foo\_Bar\_V1\_". If you don't declare a package, the prefix is the empty
string.

You can override the prefix by setting the `swift_prefix` option:

```proto
option swift_prefix = "FooBarV1";

package foo.bar.v1;
```

The prefix for types in this file is "FooBarV1" instead of "Foo\_Bar\_V1\_".

### Service namespace

For each service declared in your `.proto` file, gRPC generates a caseless
`enum` that is a namespace holding the generated protocols and types. The name
of this `enum` is `{PREFIX}{SERVICE}` where `{PREFIX}` is as described in the
previous section and `{SERVICE}` is the name of the service as declared in the
`.proto` file.

As an example, the following definition creates a service namespace `enum` called
`Foo_Bar_V1_BazService` (the `{PREFIX}` is "Foo\_Bar\_V1\_" and `{SERVICE}` is
"BazService"):

```proto
package foo.bar.v1;

service BazService {
  // ...
}
```

Code generated for each service falls into three categories:

1. Service metadata,
2. Service code, and
3. Client code.

#### Service metadata

gRPC generates metadata for each service including a descriptor identifying the
fully qualified name of the service and information about each method in the
service. You likely won't need to interact directly with this information, but
it's available if you need it.

#### Service code

Within a service namespace, gRPC generates three service protocols:

1. `StreamingServiceProtocol`,
2. `ServiceProtocol`, and
3. `SimpleServiceProtocol`.

The full name of each protocol includes the service namespace.

> Example:
>
> For the `BazService` in the `foo.bar.v1` package, the protocols are:
>
> - `Foo_Bar_V1_BazService.StreamingServiceProtocol`,
> - `Foo_Bar_V1_BazService.ServiceProtocol`, and
> - `Foo_Bar_V1_BazService.SimpleServiceProtocol`.

Each of these protocols mirrors the `service` defined in your `.proto` file
with one requirement per RPC. To implement your service, you must implement
one of these protocols.

The protocols form a hierarchy with `StreamingServiceProtocol` at the bottom and
`SimpleServiceProtocol` at the top. `ServiceProtocol` refines
`StreamingServiceProtocol`, and `SimpleServiceProtocol` refines
`ServiceProtocol` (and `StreamingServiceProtocol` in turn).

The `StreamingServiceProtocol` implements each RPC as if it were a bidirectional
streaming RPC. This gives you the most flexibility at the cost of a
harder-to-implement API. It also puts the responsibility on you to ensure that
each RPC sends and receives the correct number of messages.

The `ServiceProtocol` enforces that the correct number of messages is sent and
received through its API. It also allows you to read request metadata and send both
initial and trailing metadata. The request and response types for these
requirements are in terms of `ServerRequest` and `ServerResponse`.

The `SimpleServiceProtocol` also enforces that the correct number of messages
is sent and received through its API. However, it isn't defined in terms of
`ServerRequest` or `ServerResponse`, so it doesn't allow you to access metadata.
This limitation gives it the simplest API, and it's the best choice if you
don't need access to metadata.

| Protocol                   | Enforces number of messages | Access to metadata
|----------------------------|-----------------------------|-------------------
| `StreamingServiceProtocol` | ✗                           | ✓
| `ServiceProtocol`          | ✓                           | ✓
| `SimpleServiceProtocol`    | ✓                           | ✗

#### Client code

gRPC generates two types for the client within a service namespace:

1. `ClientProtocol`, and
2. `Client`.

Like the service code, the full name includes the namespace.

> Example:
>
> For the `BazService` in the `foo.bar.v1` package, the client types are:
>
> - `Foo_Bar_V1_BazService.ClientProtocol`, and
> - `Foo_Bar_V1_BazService.Client`.

The `ClientProtocol` defines one requirement for each RPC in terms of
`ClientRequest` and `ClientResponse`. You don't need to implement the protocol,
as `Client` provides a concrete implementation.

gRPC also generates extensions on `ClientProtocol` to provide more ergonomic
APIs. These include versions that provide default arguments for various
parameters (like the message serializer and deserializer; call options and
response handler) and versions that don't use `ClientRequest` and
`ClientResponse` directly.
