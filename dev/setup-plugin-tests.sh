#!/bin/bash
## Copyright 2024, gRPC Authors All rights reserved.
##
## Licensed under the Apache License, Version 2.0 (the "License");
## you may not use this file except in compliance with the License.
## You may obtain a copy of the License at
##
##     http://www.apache.org/licenses/LICENSE-2.0
##
## Unless required by applicable law or agreed to in writing, software
## distributed under the License is distributed on an "AS IS" BASIS,
## WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
## See the License for the specific language governing permissions and
## limitations under the License.

set -euo pipefail

log() { printf -- "** %s\n" "$*" >&2; }
error() { printf -- "** ERROR: %s\n" "$*" >&2; }
fatal() { error "$@"; exit 1; }

output_directory="${PLUGIN_TESTS_OUTPUT_DIRECTORY:=$(mktemp -d)}"

here="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
grpc_swift_protobuf_directory="$(readlink -f "${here}/..")"
resources_directory="$(readlink -f "${grpc_swift_protobuf_directory}/IntegrationTests/PluginTests/Resources")"
config="${resources_directory}/Config"
sources="${resources_directory}/Sources"
protos="${resources_directory}/Protos"
scratch_directory="$(mktemp -d)"
package_manifest="${scratch_directory}/Package.swift"

echo "Output directory: $output_directory"
echo "grpc-swift-protobuf directory: $grpc_swift_protobuf_directory"

# modify Package.swift
cp "${resources_directory}/Sources/Package.swift" "${scratch_directory}/"
cat >> "${package_manifest}" <<- EOM
package.dependencies.append(
  .package(path: "$grpc_swift_protobuf_directory")
)
EOM

function test_dir_name {
  # $FUNCNAME is a stack of function names. The 0th element is the name of this
  # function, so the 1st element is the calling function.
  echo "${output_directory}/${FUNCNAME[1]}"
}

function test_01_top_level_config_file {
  # .
  # ├── Package.swift
  # └── Sources
  #     ├── HelloWorldAdopter.swift
  #     ├── Protos
  #     │   └── HelloWorld.proto
  #     └── grpc-swift-proto-generator-config.json

  local -r test_dir=$(test_dir_name)
  mkdir -p "${test_dir}/Sources/Protos"
  cp "${package_manifest}" "${test_dir}/"
  cp "${sources}/HelloWorldAdopter.swift" "${test_dir}/Sources/"
  cp "${protos}/HelloWorld/HelloWorld.proto" "${test_dir}/Sources/Protos"
  cp "${config}/internal-grpc-swift-proto-generator-config.json" "${test_dir}/Sources/grpc-swift-proto-generator-config.json"
}

function test_02_peer_config_file {
  # .
  # ├── Package.swift
  # └── Sources
  #     ├── HelloWorldAdopter.swift
  #     └── Protos
  #         ├── HelloWorld.proto
  #         └── grpc-swift-proto-generator-config.json

  local -r test_dir=$(test_dir_name)
  mkdir -p "${test_dir}/Sources/Protos"
  cp "${package_manifest}" "${test_dir}/"
  cp "${sources}/HelloWorldAdopter.swift" "${test_dir}/Sources/"
  cp "${protos}/HelloWorld/HelloWorld.proto" "${test_dir}/Sources/Protos/"
  cp "${config}/internal-grpc-swift-proto-generator-config.json" "${test_dir}/Sources/Protos/grpc-swift-proto-generator-config.json"
}

function test_03_separate_service_message_protos {
  # .
  # ├── Package.swift
  # └── Sources
  #     ├── HelloWorldAdopter.swift
  #     └── Protos
  #         ├── Messages.proto
  #         ├── Service.proto
  #         └── grpc-swift-proto-generator-config.json

  local -r test_dir=$(test_dir_name)
  mkdir -p "${test_dir}/Sources/Protos"
  cp "${package_manifest}" "${test_dir}/"
  cp "${sources}/HelloWorldAdopter.swift" "${test_dir}/Sources/"
  cp "${config}/internal-grpc-swift-proto-generator-config.json" "${test_dir}/Sources/Protos/grpc-swift-proto-generator-config.json"
  cp "${protos}/HelloWorld/Service.proto"  "${test_dir}/Sources/Protos/"
  cp "${protos}/HelloWorld/Messages.proto"  "${test_dir}/Sources/Protos/"
}

function test_04_cross_directory_imports {
  # .
  # ├── Package.swift
  # └── Sources
  #     ├── HelloWorldAdopter.swift
  #     └── Protos
  #         ├── directory_1
  #         │   ├── Messages.proto
  #         │   └── grpc-swift-proto-generator-config.json
  #         └── directory_2
  #             ├── Service.proto
  #             └── grpc-swift-proto-generator-config.json

  local -r test_dir=$(test_dir_name)
  mkdir -p "${test_dir}/Sources/Protos/directory_1"
  mkdir -p "${test_dir}/Sources/Protos/directory_2"

  cp "${package_manifest}" "${test_dir}/"
  cp "${sources}/HelloWorldAdopter.swift" "${test_dir}/Sources/"
  cp "${config}/internal-grpc-swift-proto-generator-config.json" "${test_dir}/Sources/Protos/directory_1/grpc-swift-proto-generator-config.json"
  cp "${config}/import-directory-1-grpc-swift-proto-generator-config.json" "${test_dir}/Sources/Protos/directory_2/grpc-swift-proto-generator-config.json"
  cp "${protos}/HelloWorld/Service.proto" "${test_dir}/Sources/Protos/directory_2/"
  cp "${protos}/HelloWorld/Messages.proto" "${test_dir}/Sources/Protos/directory_1/"
}

function test_05_two_definitions {
  # .
  # ├── Package.swift
  # └── Sources
  #     ├── FooHelloWorldAdopter.swift
  #     └── Protos
  #         ├── Foo
  #         │   ├── foo-messages.proto
  #         │   └── foo-service.proto
  #         ├── HelloWorld
  #         │   └── HelloWorld.proto
  #         └── grpc-swift-proto-generator-config.json

  local -r test_dir=$(test_dir_name)
  mkdir -p "${test_dir}/Sources/Protos/HelloWorld"
  mkdir -p "${test_dir}/Sources/Protos/Foo"

  cp "${package_manifest}" "${test_dir}/"
  cp "${sources}/FooHelloWorldAdopter.swift" "${test_dir}/Sources/"
  cp "${protos}/HelloWorld/HelloWorld.proto" "${test_dir}/Sources/Protos/HelloWorld/"
  cp "${config}/internal-grpc-swift-proto-generator-config.json" "${test_dir}/Sources/Protos/grpc-swift-proto-generator-config.json"
  cp "${protos}/Foo/foo-messages.proto" "${test_dir}/Sources/Protos/Foo/"
  cp "${protos}/Foo/foo-service.proto" "${test_dir}/Sources/Protos/Foo/"
}

function test_06_nested_definitions {
  # .
  # ├── Package.swift
  # └── Sources
  #     ├── FooHelloWorldAdopter.swift
  #     └── Protos
  #         └── HelloWorld
  #             ├── FooDefinitions
  #             │   ├── Foo
  #             │   │   ├── foo-messages.proto
  #             │   │   └── foo-service.proto
  #             │   └── grpc-swift-proto-generator-config.json
  #             ├── HelloWorld.proto
  #             └── grpc-swift-proto-generator-config.json

  local -r test_dir=$(test_dir_name)
  mkdir -p "${test_dir}/Sources/Protos/HelloWorld/FooDefinitions/Foo"
  cp "${package_manifest}" "${test_dir}/"
  cp "${sources}/FooHelloWorldAdopter.swift" "${test_dir}/Sources/"
  cp "${protos}/HelloWorld/HelloWorld.proto" "${test_dir}/Sources/Protos/HelloWorld/"
  cp "${config}/internal-grpc-swift-proto-generator-config.json" "${test_dir}/Sources/Protos/HelloWorld/grpc-swift-proto-generator-config.json"
  cp "${config}/public-grpc-swift-proto-generator-config.json" "${test_dir}/Sources/Protos/HelloWorld/FooDefinitions/grpc-swift-proto-generator-config.json"
  cp "${protos}/Foo/foo-messages.proto" "${test_dir}/Sources/Protos/HelloWorld/FooDefinitions/Foo/"
  cp "${protos}/Foo/foo-service.proto" "${test_dir}/Sources/Protos/HelloWorld/FooDefinitions/Foo/"
}

function test_07_duplicated_proto_file_name {
  # .
  # ├── Package.swift
  # └── Sources
  #     ├── NoOp.swift
  #     └── Protos
  #         ├── grpc-swift-proto-generator-config.json
  #         ├── noop
  #         │   └── noop.proto
  #         └── noop2
  #             └── noop.proto

  local -r test_dir=$(test_dir_name)
  mkdir -p "${test_dir}/Sources/Protos"

  cp "${package_manifest}" "${test_dir}/"
  mkdir -p "${test_dir}/Sources/Protos"
  cp -rp "${protos}/noop" "${test_dir}/Sources/Protos"
  cp -rp "${protos}/noop2" "${test_dir}/Sources/Protos"
  cp "${sources}/NoOp.swift" "${test_dir}/Sources"
  cp "${config}/internal-grpc-swift-proto-generator-config.json" "${test_dir}/Sources/Protos/grpc-swift-proto-generator-config.json"
}

test_01_top_level_config_file
test_02_peer_config_file
test_03_separate_service_message_protos
test_04_cross_directory_imports
test_05_two_definitions
test_06_nested_definitions
test_07_duplicated_proto_file_name
