# Generating stubs

Learn about the different options for generating stubs for gRPC Swift.

## Overview

There are three primary approaches to generating stubs for your gRPC Swift
project:

1. **Using `protoc` from the command line:** This is a common method for those
   familiar with gRPC or Protocol Buffers. It requires directly invoking
   `protoc` along with the gRPC Swift and Swift Protobuf plugins. See
   also <doc:Code-generation-with-protoc>.
2. **Using a helper CLI provided by this package:** This tool,
   `generate-grpc-code-from-protos`, simplifies the
   process by wrapping `protoc`. It builds and locates `protoc` plugins for you
   and exposes various generation options as command-line arguments.
3. **Using a Swift Package Manager build plugin:** This approach integrates stub
   generation directly into your project's build graph, generating stubs
   automatically at build time. See <doc:Code-generation-with-the-build-plugin> for
   more information.

## Deciding which approach to take

Each method has its own trade-offs. This section helps you choose the best
approach for your specific use case.

### For applications (self-contained packages)

If you are building an **application** (meaning no other packages depend on
yours), you **may** use the Swift Package Manager build plugin.

- **Pros:** The build plugin generates stubs as part of your package's build
  process, eliminating the need for manual generation steps.

### For libraries (dependent packages)

If you are building a **library** (a package that other packages depend
on), you may still prefer to generate stubs out-of-band using either:

- `protoc` directly from the command line, or
- the helper CLI tool offered by this package.

You must then include the generated code directly with the source files of your
library package. This avoids the first-time build cost of compiling `protoc`
from source for consumers of your library.

### The CLI tool

The `generate-grpc-code-from-protos` tool provides a simpler, more
user-friendly alternative to invoking `protoc` directly. It automates the process
of building the necessary gRPC Swift and Swift Protobuf plugins for `protoc` and
provides a simpler interface for configuring generation options. It is often the
most convenient way to generate code for your gRPC project.

### Summary and next steps

This table summarizes the three approaches:

|                                   | `protoc` | `generate-grpc-code-from-protos` | Build plugin
|-----------------------------------|----------|----------------------------------|--------------
| Suitable for libraries            | Yes      | Yes                              | Yes†
| Suitable for applications         | No       | No                               | Yes
| Builds plugins for you            | No       | Yes                              | Yes
| Generated at build time           | No       | No                               | Yes
| Generated code must be checked in | Yes      | Yes                              | No

† Using the build plugin in a library means consumers incur a one-time cost of
compiling `protoc` from source. Libraries may prefer checking in generated code
to avoid this.

You can learn more about each approach in:
- <doc:Code-generation-with-protoc>
- <doc:Code-generation-with-the-command-plugin>
- <doc:Code-generation-with-the-build-plugin>
