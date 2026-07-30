# Code generation with generate-grpc-code-from-protos

This article describes how to use the `generate-grpc-code-from-protos` Swift
Package Manager command plugin to generate gRPC Swift and Swift Protobuf code
from your Protocol Buffers `.proto` files.

This plugin is particularly useful for:

- **Manual, on-demand code generation:** When you prefer to explicitly generate
  code rather than relying on a build tool plugin.
- **Libraries:** For Swift packages intended as libraries, where you should
  check generated source code into your repository to avoid external `protoc`
  dependencies for your library's consumers.

## Adding the plugin to your package

To use `generate-grpc-code-from-protos`, your package needs to depend on
`grpc-swift-protobuf`. You **don't** need to add a dependency on each target
like you would for the build plugin.

## Basic usage

Once your package depends on `grpc-swift-protobuf`, you can invoke it using:

```sh
swift package generate-grpc-code-from-protos path/to/YourService.proto path/to/YourMessages.proto
```

If you've organized your protos within a single directory, you can pass the
path of the directory as an argument instead. The plugin finds all `.proto`
files nested within that directory:

```sh
swift package generate-grpc-code-from-protos Protos
```

By default, the plugin generates code for gRPC servers, clients, and Protobuf
messages into the current working directory. To change where the code is
generated, you can specify the `--output-path` option:

```sh
swift package generate-grpc-code-from-protos --output-path Sources/Generated -- Protos
```

> Important: The `--` separates options and inputs passed to the plugin.
>
> The plugin treats everything after `--` as an input (a `.proto` file or a
> directory) and everything before `--` as an option with a value or a flag.
> If there's no `--`, the plugin treats all arguments as input.

You should now have a basic understanding of how to use the plugin. You can
configure how the code is generated using a number of options. Here are a few
commonly used options:
- `--no-client` disables client code generation.
- `--no-server` disables server code generation.
- `--no-messages` disables message code generation.
- `--access-level <access>` specifies the access level of the generated code
  (`<access>` must be one of "internal", "package", or "public").
- `--protoc-path <path>` overrides the vendored `protoc` with a specific
  binary. You can also use the `PROTOC_PATH` environment variable as an
  override.

For a full list of options, run the plugin with the `--help` flag:

```sh
swift package generate-grpc-code-from-protos --help
```

### Permissions

Swift Package Manager command plugins require permission to create files. You'll
be prompted to give `generate-grpc-code-from-protos` permission when running it.
To avoid being prompted, you can grant permissions ahead of time by specifying
`--allow-writing-to-package-directory` to the `swift package` command. For
example:

```sh
swift package --allow-writing-to-package-directory generate-grpc-code-from-protos Protos
```
