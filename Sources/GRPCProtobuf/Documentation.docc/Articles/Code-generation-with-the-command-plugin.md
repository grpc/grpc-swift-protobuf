# Code generation with generate-grpc-code-from-protos

This article describes how to use the `generate-grpc-code-from-protos` Swift
Package Manager command plugin to generate gRPC Swift and Swift Protobuf code
from your Protocol Buffers `.proto` files.

This plugin is particularly useful for:

- **Manual, on-demand code generation:** When you prefer to explicitly generate
  code rather than relying on a build tool plugin.
- **Libraries:** For Swift packages intended as libraries, where generated
  source code should be checked into your repository to avoid external `protoc`
  dependencies for your library's consumers.

If you haven't installed `protoc` yet refer to <doc:Installing-protoc> for
instructions.

## Adding the Plugin to Your Package

To use `generate-grpc-code-from-protos` your package needs to depend on
`grpc-swift-protobuf`. You **don't** need to add a dependency on each target
like you would for the build plugin.

## Basic Usage

Once your package depends on `grpc-swift-protobuf` you can invoke it using:

```sh
swift package generate-grpc-code-from-protos path/to/YourService.proto path/to/YourMessages.proto
```

If you've organised your protos within a single directory then you can
pass the path of the directory as an argument instead, the plugin will find
all `.proto` files nested within that directory:

```sh
swift package generate-grpc-code-from-protos Protos
```

By default the plugin generates code for gRPC servers, clients, and Protobuf
messages into the current working directory. To change where the code is
generated you can specify the `--output-path` option:


```sh
swift package generate-grpc-code-from-protos --output-path Sources/Generated -- Protos
```

> Important: The "`--`" separates options and inputs passed to the plugin.
>
> Everything after "`--`" is treated as an input (a `.proto` file or a
> directory), everything before "`--`" is treated as an option with a value or
> a flag. If there is no "`--`" then all arguments are treated as input.

You should now have a basic understanding of how to use the plugin. You can
configure how the code is generated via a number of options, a few commonly used
ones are:
- `--no-client` disables client code generation,
- `--no-server` disables server code generation,
- `--no-messages` disables message code generation,
- `--access-level <access>` specifies the access level of the generated code,
  (`<access>` must be one of "internal", "package", or "public").

You can read about other options by referring to the `--help` text:

```sh
swift package generate-grpc-code-from-protos --help
```

### Permissions

Swift Package Manager command plugins require permission to create files. You'll
be prompted to give `generate-grpc-code-from-protos` permission when running it.
To avoid being prompted you can grant permissions ahead of time by specifying
`--allow-writing-to-package-directory` to the `swift package` command. For
example:

```sh
swift package --allow-writing-to-package-directory generate-grpc-code-from-protos Protos
```
