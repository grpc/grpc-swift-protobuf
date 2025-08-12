# Code generation with the build plugin

This article describes how to use `protoc` to generate stubs for gRPC Swift and
Swift Protobuf from your Protocol Buffers `.proto` files.

## Overview

The build plugin (`GRPCProtobufGenerator`) is a great choice for convenient
dynamic code generation, however it does come with some limitations. Because it
generates the gRPC Swift stubs as part of the build it has the requirement that
`protoc` must be available at compile time. This requirement means it is not a
good fit for library authors who do not have direct control over this.

To learn more about other options for code generation see <doc:Generating-stubs>.

The build plugin works by detecting `.proto` files in the source tree and
invokes `protoc` once for each file (caching results and performing the
generation as necessary).

If you haven't installed `protoc` yet refer to <doc:Installing-protoc> for
instructions.

### Adoption

You must adopt Swift Package Manager build plugins on a per-target basis by
modifying your package manifest (`Package.swift` file). To do this, declare the
`grpc-swift-protobuf` package as a dependency and add the plugin to your desired
targets.

For example, to make use of the plugin for generating gRPC Swift stubs as part
of the `echo-server` target:

```swift
targets: [
   .executableTarget(
     name: "echo-server",
     dependencies: [
       // ...
     ],
     plugins: [
       .plugin(
         name: "GRPCProtobufGenerator",
         package: "grpc-swift-protobuf"
       )
     ]
   )
 ]
```

Once this is done you need to ensure that the `.proto` files to be used for
generation are included in the target's source directory and that you have
defined a configuration file.

## Configuration

You must provide a configuration file named
`grpc-swift-proto-generator-config.json` in the directory which encloses all
`.proto` files (in the same directory as the files or a parent directory). The
configuration file tells the build plugin about the options used for `protoc`
invocations.

> Warning:
> The name of the config file is important and must match exactly, the
> plugin won't be applied if it can't find the config file.

You can use the following as a starting point for your configuration:

```json
{
  "generate": {
    "clients": true,
    "servers": true,
    "messages": true
  }
}
```

By default clients, servers, and messages will be generated with the `internal`
access level.

The full structure of the config file looks like this:

```json
{
  "generate": {
    "clients": true,
    "servers": true,
    "messages": true
  },
  "generatedSource": {
    "accessLevelOnImports": false,
    "accessLevel": "internal"
  },
  "protoc": {
    "executablePath": "/opt/homebrew/bin/protoc",
    "importPaths": [
      "../directory_1"
    ]
  }
}
```

Each of the options are described below:

| Name                                   | Possible Values                            | Default      | Description                                         |
|----------------------------------------|--------------------------------------------|--------------|-----------------------------------------------------|
| `generate.servers`                     | `true`, `false`                            | `true`       | Generate server stubs                               |
| `generate.clients`                     | `true`, `false`                            | `true`       | Generate client stubs                               |
| `generate.messages`                    | `true`, `false`                            | `true`       | Generate message stubs                              |
| `generatedSource.accessLevelOnImports` | `true`, `false`                            | `false`      | Whether imports should have explicit access levels  |
| `generatedSource.accessLevel`          | `"public"`, `"package"`, `"internal"`      | `"internal"` | Access level for generated stubs                    |
| `protoc.executablePath`                | N/A                                        | `null`†      | Path to the `protoc` executable                     |
| `protoc.importPaths`                   | N/A                                        | `null`‡      | Import paths passed to `protoc`                     |

† The Swift Package Manager build plugin infrastructure will attempt to discover
the executable's location if you don't provide one.

‡ If you don't provide any import paths then the path to the configuration file
will be used on a per-source-file basis.

Many of these options map to `protoc-gen-grpc-swift-2` and `protoc-gen-swift`
options.

If you require greater flexibility you may specify more than one configuration
file. Configuration files apply to all `.proto` files equal to or below it in
the file hierarchy. A configuration file lower in the file hierarchy supersedes
one above it.
