# Code generation with the build plugin

This article describes how to use `protoc` to generate stubs for gRPC Swift and
Swift Protobuf from your Protocol Buffers `.proto` files.

## Overview

The build plugin (`GRPCProtobufGenerator`) generates gRPC Swift stubs as part of
your build. It uses a vendored copy of `protoc` provided by the `swift-protobuf`
package, so no separate installation is required.

To learn more about other options for code generation see <doc:Generating-stubs>.

The build plugin works by detecting `.proto` files in the source tree and
invokes `protoc` once for each file (caching results and performing the
generation as necessary).

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

† By default a vendored copy of `protoc` from `swift-protobuf` is used. To
override it, set `protoc.executablePath` in the configuration file or the
`PROTOC_PATH` environment variable. If both are set, `protoc.executablePath`
takes precedence.

‡ If you don't provide any import paths then the path to the configuration file
will be used on a per-source-file basis.

Many of these options map to `protoc-gen-grpc-swift-2` and `protoc-gen-swift`
options.

If you require greater flexibility you may specify more than one configuration
file. Configuration files apply to all `.proto` files equal to or below it in
the file hierarchy. A configuration file lower in the file hierarchy supersedes
one above it.
