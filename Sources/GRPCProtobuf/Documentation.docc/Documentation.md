# ``GRPCProtobuf``

A package integrating Swift Protobuf with gRPC Swift.

## Overview

This package provides three products:
- ``GRPCProtobuf``, a module providing runtime serialization and deserialization components for
  [SwiftProtobuf](https://github.com/apple/swift-protobuf).
- `protoc-gen-grpc-swift-2`, an executable which is a plugin for `protoc`, the Protocol Buffers
  compiler. An article describing how to generate gRPC Swift stubs using it is available with the
  `grpc-swift` documentation on the [Swift Package
  Index](https://swiftpackageindex.com/grpc/grpc-swift/documentation).
- `GRPCProtobufGenerator`, a Swift Package build plugin for generating stubs as part of the build
  process.


## Topics

### Essentials

- <doc:Installing-protoc>
- <doc:Generating-stubs>
- <doc:API-stability-of-generated-code>
- <doc:Understanding-the-generated-code>
- <doc:Public-services-with-private-implementations>

### Serialization

- ``ProtobufSerializer``
- ``ProtobufDeserializer``
