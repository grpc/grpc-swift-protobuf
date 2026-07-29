# API stability of generated code

Understand the impact of changes you make to your Protocol Buffers files on the
generated Swift code.

## Overview

The API of the generated code depends on three factors:

- The contents of the source `.proto` file.
- The options you use when generating the code.
- The code generator (the `protoc-gen-grpc-swift-2` plugin for `protoc`).

While this document applies specifically to the gRPC code generated and *not*
code for messages used as inputs and outputs of each method, the concepts still
broadly apply.

Some of the concepts used in this document are described in more detail in
<doc:Understanding-the-generated-code>.

## The source .proto file

The source `.proto` file defines the API of your service. You'll likely provide
it to users so that they can generate clients from it. To maintain API
stability for your service and for clients, you must adhere to the following
rules:

1. You mustn't change the `package` the service is defined in.
2. You mustn't change or add the `swift_prefix` option.
3. You mustn't remove or change the name of any services in your `.proto` file.
4. You mustn't remove or change the name of any RPCs in your `.proto` file.
5. You mustn't change the message types used by any RPCs in your `.proto` file.

Failing to follow these rules results in changes to the generated code, which
can cause build failures for users.

While this sounds restrictive, you can do the following:

1. You may add a new RPC to an existing service in your `.proto` file.
2. You may add a new service to your `.proto` file (however, we recommend
   defining a single service per `.proto` file).

## The options you use for generating code

Code you generate into your package becomes part of your package's API. You
must therefore make sure the options you use when generating code don't
affect downstream users of your package.

By default, code is generated at the `internal` access level and therefore
isn't part of the public API. You must explicitly opt in to generating code at
the `public` access level. If you do this, you must be aware that changing what
is generated (clients, servers) affects the public API, as does the access level
of the generated code.

If you need to validate whether your API has changed, you can use tools like
Swift Package Manager's API breakage diagnostic (`swift package
diagnose-api-breaking-changes`). In general, you should prefer providing users
with the service's `.proto` file so that they can generate clients, or provide a
library that wraps the client to hide the API of the generated code.

## The code generator

The gRPC Swift maintainers may need to evolve the generated code over time, but
they'll do so in a source-compatible way.

If APIs are no longer suitable, the maintainers may deprecate them in favor of
new ones. Within a major version of the package, the maintainers won't remove
existing API, and deprecated APIs continue to function.

If the generator introduces new ways to generate code that are incompatible
with the previously generated code, they require explicit opt-in through an
option.

As gRPC Swift is developed, the generated code may need to rely on newer
functionality from its runtime counterparts (`GRPCCore` and `GRPCProtobuf`).
This means you should use the versions of `protoc-gen-grpc-swift-2` and
`protoc-gen-swift` resolved with your package rather than obtaining them from
an out-of-band source such as Homebrew.
