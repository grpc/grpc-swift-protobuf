# API stability of generated code

Understand the impact of changes you make to your Protocol Buffers files on the
generated Swift code.

## Overview

The API of the generated code depends on three factors:

- The contents of the source `.proto` file.
- The options you use when generating the code.
- The code generator (the `protoc-gen-grpc-swift` plugin for `protoc`).

While this document applies specifically to the gRPC code generated and *not*
code for messages used as inputs and outputs of each method, the concepts still
broadly apply.

Some of the concepts used in this document are described in more detail in
<doc:Understanding-the-generated-code>.

## The source .proto file

The source `.proto` file defines the API of your service. You'll likely provide
it to users so that they can generate clients from it. In order to maintain API
stability for your service and for clients you must adhere to the following
rules:

1. You mustn't change the `package` the service is defined in.
2. You mustn't change or add the `swift_prefix` option.
3. You mustn't remove or change the name of any services in your `.proto` file.
4. You mustn't remove or change the name of any RPCs in your `.proto` file.
5. You mustn't change the message types used by any RPCs in your `.proto` file.

Failure to follow these will result in changes in the generated code which can
result in build failures for users.

Whilst this sounds restrictive you may do the following:

1. You may add a new RPC to an existing service in your `.proto` file.
2. You may add a new service to your `.proto` file (however it is recommended
   that you define a single service per `.proto` file).

## The options you use for generating code

Code you generate into your Swift Package becomes part of the API of your
package. You must therefore ensure that downstream users of your package aren't
impacted by the options you use when generating code.

By default code is generated at the `internal` access level and therefore not
part of the public API. You must explicitly opt in to generating code at the
`public` access level. If you do this then you must be aware that changing what
is generated (clients, servers) affects the public API, as does the access level
of the generated code.

If you need to validate whether your API has changed you can use tools like
Swift Package Manager's API breakage diagnostic (`swift package
diagnose-api-breaking-changes`.) In general you should prefer providing users
with the service's `.proto` file so that they can generate clients, or provide a
library which wraps the client to hide the API of the generated code.

## The code generator

The gRPC Swift maintainers may need to evolve the generated code over time. This
will be done in a source-compatible way.

If APIs are no longer suitable then they may be deprecated in favour of new
ones. Existing API will never be removed and deprecated APIs will continue to
function.

If the generator introduces new ways to generate code which are incompatible
with the previously generated code then they will require explicit opt-in via an
option.

As gRPC Swift is developed the generated code may need to rely on newer
functionality from its runtime counterparts (`GRPCCore` and `GRPCProtobuf`).
This means that you should use the versions of `protoc-gen-grpc-swift` and
`protoc-gen-swift` resolved with your package rather than getting them from an
out-of-band (such as `homebrew`).
