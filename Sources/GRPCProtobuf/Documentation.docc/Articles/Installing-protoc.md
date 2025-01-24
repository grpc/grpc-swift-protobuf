# Installing protoc

Learn how to install `protoc`, the Protocol Buffers compiler.

## Overview

The Protocol Buffers compiler is a command line tool for generating source code from `.proto`
files and is required to generate gRPC stubs and messages. You can learn more about it on the
[Protocol Buffers website](https://protobuf.dev/).

You can install `protoc` in a number of ways including:

1. Via a package manager,
2. By downloading the binary.

### Install via a package manager

Using a package manager is the easiest way to install `protoc`.

On macOS you can use [Homebrew](https://brew.sh):

```sh
brew install protobuf
```

On Ubuntu and Debian you can use `apt`:

```sh
apt update && apt install -y protobuf-compiler
```

On Fedora you can use `dnf`:

```sh
dnf install -y protobuf-compiler
```

### Installing a pre-built binary

If you're unable to use a package manager to install `protoc` then you may be able
to download a pre-built binary from the [Protocol Buffers GitHub
repository](https://github.com/protocolbuffers/protobuf).

First, find and download the appropriate binary for your system from the
 [releases](https://github.com/protocolbuffers/protobuf/releases) page.

Next, unzip the artifact to a directory called `protoc`:

```sh
unzip /path/to/downloaded/protoc-{VERSION}-{OS}.zip -d protoc
```

Finally, move `protoc/bin/protoc` to somewhere in your `$PATH` such as `/usr/local/bin`:

```sh
mv protoc/bin/protoc /usr/local/bin
```

You can now remove the `protoc` directory.
