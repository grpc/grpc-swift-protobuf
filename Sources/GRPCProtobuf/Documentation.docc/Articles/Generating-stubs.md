# Generating stubs

Learn about the different options for generating stubs for gRPC Swift.

## Overview

There are three primary approaches to generate stubs for your gRPC Swift
project:

1. **Using `protoc` from the command line:** This is a common method for those
   familiar with gRPC or Protocol Buffers. It requires directly invoking
   `protoc` along with the gRPC Swift and Swift Protobuf plugins. See
   also <doc:Code-generation-with-protoc>.
2. **Using a helper CLI provided by this package:** This tool,
   `generate-grpc-code-from-protos`, simplifies the
   process by wrapping protoc. It handles the building and locating of `protoc`
   plugins for you, and exposes various generation options as command-line
   arguments.
3. **Using a Swift Package Manager build plugin:** This approach integrates stub
   generation directly into your project's build graph, generating stubs
   automatically at build time. See <doc:Code-generation-with-the-build-plugin> for
   more information.

## Deciding Which Approach to Take

Each method has its own trade-offs. This section will help you choose the best
approach for your specific use case.

### For Applications (self-contained packages)

If you are building an **application** (meaning no other packages will depend on
yours), you **may** use the Swift Package Manager build plugin.

- **Pros:** Stubs are generated as part of your package's build process,
  eliminating the need for manual generation steps.
- **Cons:** The `protoc` binary must be available in all environments where
  you build your package, including continuous integration (CI) systems.

### For Libraries (dependent packages)

If you are building a **library** (a package that other packages will depend
on), you **must not** use the build plugin.

- **Reason:** You cannot guarantee that consumers of your library will have
  protoc available in their build environments.
- **Recommended Approach:** Instead, you must generate stubs out-of-band using
  either:
  - `protoc` directly from the command line, or
  - The helper CLI tool offered by this package.
- **Requirement:** The generated code must then be included directly with the
  source files of your library package.

### The CLI Tool

The `generate-grpc-code-from-protos` tool is designed to be a simpler and more
user-friendly alternative to invoking `protoc` directly. It automates the process
of building the necessary gRPC and Protobuf plugins for `protoc` and provides
a simpler interface for configuring generation options. It is often the most
convenient way to generate code for your gRPC project.

### Summary and Next Steps

This table summarizes the three different approaches:

|                                   | `protoc` | `generate-grpc-code-from-protos` | Build Plugin
|-----------------------------------|----------|----------------------------------|--------------
| Suitable for libraries            | ✓        | ✓                                | ✗
| Suitable for applications         | ✗        | ✗                                | ✓
| Builds plugins for you            | ✗        | ✓                                | ✓
| Generated at build time           | ✗        | ✗                                | ✓
| Generated code must be checked in | ✓        | ✓                                | ✗

You can learn more about each approach in:
- <doc:Code-generation-with-protoc>
- <doc:Code-generation-with-the-command-plugin>
- <doc:Code-generation-with-the-build-plugin>
