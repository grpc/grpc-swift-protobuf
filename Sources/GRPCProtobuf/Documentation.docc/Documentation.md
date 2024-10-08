# ``GRPCProtobuf``

A package integrating Swift Protobuf with gRPC Swift.

## Overview

This package provides two products:
- ``GRPCProtobuf``, a module providing runtime serialization and deserialization components for
  [SwiftProtobuf](https://github.com/apple/swift-protobuf).
- `protoc-gen-grpc-swift`, an executable which is a plugin for `protoc`, the Protocol Buffers
  compiler. An article describing how to generate gRPC Swift stubs using it is available with the
  `grpc-swift` documentation on the [Swift Package
  Index](https://swiftpackageindex.com/grpc/grpc-swift/documentation).

## Topics

### Serialization

- ``ProtobufSerializer``
- ``ProtobufDeserializer``
