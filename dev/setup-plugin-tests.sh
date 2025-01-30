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
scratch_directory="$(mktemp -d)"

echo "Output directory: $output_directory"
echo "grpc-swift-protobuf directory: $grpc_swift_protobuf_directory"

# modify Package.swift
cp "${resources_directory}/Package.swift" "${scratch_directory}/"
cat >> "${scratch_directory}/Package.swift" <<- EOM
package.dependencies.append(
  .package(path: "$grpc_swift_protobuf_directory")
)
EOM

# test_01_top_level_config_file
test_01_output_directory="${output_directory}/test_01_top_level_config_file"
mkdir -p "${test_01_output_directory}/Sources/Protos"
cp "${scratch_directory}/Package.swift" "${test_01_output_directory}/"
cp "${resources_directory}/HelloWorldAdopter.swift" "${test_01_output_directory}/Sources/adopter.swift"
cp "${resources_directory}/HelloWorld/HelloWorld.proto" "${test_01_output_directory}/Sources/Protos"
cp "${resources_directory}/internal-grpc-swift-proto-generator-config.json" "${test_01_output_directory}/Sources/grpc-swift-proto-generator-config.json"

# test_02_peer_config_file
test_02_output_directory="${output_directory}/test_02_peer_config_file"
mkdir -p "${test_02_output_directory}/Sources/Protos"
cp "${scratch_directory}/Package.swift" "${test_02_output_directory}/"
cp "${resources_directory}/HelloWorldAdopter.swift" "${test_02_output_directory}/Sources/adopter.swift"
cp "${resources_directory}/HelloWorld/HelloWorld.proto" "${test_02_output_directory}/Sources/Protos/"
cp "${resources_directory}/internal-grpc-swift-proto-generator-config.json" "${test_02_output_directory}/Sources/Protos/grpc-swift-proto-generator-config.json"

# test_03_separate_service_message_protos
test_03_output_directory="${output_directory}/test_03_separate_service_message_protos"
mkdir -p "${test_03_output_directory}/Sources/Protos"
cp "${scratch_directory}/Package.swift" "${test_03_output_directory}/"
cp "${resources_directory}/HelloWorldAdopter.swift" "${test_03_output_directory}/Sources/adopter.swift"
cp "${resources_directory}/internal-grpc-swift-proto-generator-config.json" "${test_03_output_directory}/Sources/Protos/grpc-swift-proto-generator-config.json"
cp "${resources_directory}/HelloWorld/Service.proto"  "${test_03_output_directory}/Sources/Protos/"
cp "${resources_directory}/HelloWorld/Messages.proto"  "${test_03_output_directory}/Sources/Protos/"

# test_04_cross_directory_imports
test_04_output_directory="${output_directory}/test_04_cross_directory_imports"
mkdir -p "${test_04_output_directory}/Sources/Protos/directory_1"
mkdir -p "${test_04_output_directory}/Sources/Protos/directory_2"
cp "${scratch_directory}/Package.swift" "${test_04_output_directory}/"
cp "${resources_directory}/HelloWorldAdopter.swift" "${test_04_output_directory}/Sources/adopter.swift"
cp "${resources_directory}/internal-grpc-swift-proto-generator-config.json" "${test_04_output_directory}/Sources/Protos/directory_1/grpc-swift-proto-generator-config.json"
cp "${resources_directory}/import-directory-1-grpc-swift-proto-generator-config.json" "${test_04_output_directory}/Sources/Protos/directory_2/grpc-swift-proto-generator-config.json"
cp "${resources_directory}/HelloWorld/Service.proto" "${test_04_output_directory}/Sources/Protos/directory_2/"
cp "${resources_directory}/HelloWorld/Messages.proto" "${test_04_output_directory}/Sources/Protos/directory_1/"

# test_05_two_definitions
test_05_output_directory="${output_directory}/test_05_two_definitions"
mkdir -p "${test_05_output_directory}/Sources/Protos/HelloWorld"
mkdir -p "${test_05_output_directory}/Sources/Protos/Foo"
cp "${scratch_directory}/Package.swift" "${test_05_output_directory}/"
cp "${resources_directory}/FooHelloWorldAdopter.swift" "${test_05_output_directory}/Sources/adopter.swift"
cp "${resources_directory}/HelloWorld/HelloWorld.proto" "${test_05_output_directory}/Sources/Protos/HelloWorld/"
cp "${resources_directory}/internal-grpc-swift-proto-generator-config.json" "${test_05_output_directory}/Sources/Protos/grpc-swift-proto-generator-config.json"
cp "${resources_directory}/Foo/foo-messages.proto" "${test_05_output_directory}/Sources/Protos/Foo/"
cp "${resources_directory}/Foo/foo-service.proto" "${test_05_output_directory}/Sources/Protos/Foo/"

# test_06_nested_definitions
test_06_output_directory="${output_directory}/test_06_nested_definitions"
mkdir -p "${test_06_output_directory}/Sources/Protos/HelloWorld/FooDefinitions/Foo"
cp "${scratch_directory}/Package.swift" "${test_06_output_directory}/"
cp "${resources_directory}/FooHelloWorldAdopter.swift" "${test_06_output_directory}/Sources/adopter.swift"
cp "${resources_directory}/HelloWorld/HelloWorld.proto" "${test_06_output_directory}/Sources/Protos/HelloWorld/"
cp "${resources_directory}/internal-grpc-swift-proto-generator-config.json" "${test_06_output_directory}/Sources/Protos/HelloWorld/grpc-swift-proto-generator-config.json"
cp "${resources_directory}/public-grpc-swift-proto-generator-config.json" "${test_06_output_directory}/Sources/Protos/HelloWorld/FooDefinitions/grpc-swift-proto-generator-config.json"
cp "${resources_directory}/Foo/foo-messages.proto" "${test_06_output_directory}/Sources/Protos/HelloWorld/FooDefinitions/Foo/"
cp "${resources_directory}/Foo/foo-service.proto" "${test_06_output_directory}/Sources/Protos/HelloWorld/FooDefinitions/Foo/"
