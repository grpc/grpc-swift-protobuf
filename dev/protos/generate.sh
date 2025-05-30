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

set -eu

here="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
root="$here/../.."
protoc=$(which protoc)

# Checkout and build the plugins.
swift build --package-path "$root" --product protoc-gen-swift
swift build --package-path "$root" --product protoc-gen-grpc-swift-2

# Grab the plugin paths.
bin_path=$(swift build --package-path "$root" --show-bin-path)
protoc_gen_swift="$bin_path/protoc-gen-swift"
protoc_gen_grpc_swift="$bin_path/protoc-gen-grpc-swift-2"

# Generates gRPC by invoking protoc with the gRPC Swift plugin.
# Parameters:
# - $1: .proto file
# - $2: proto path
# - $3: output path
# - $4 onwards: options to forward to the plugin
function generate_grpc {
  local proto=$1
  local args=("--plugin=$protoc_gen_grpc_swift" "--proto_path=${2}" "--grpc-swift-2_out=${3}")

  for option in "${@:4}"; do
    args+=("--grpc-swift-2_opt=$option")
  done

  invoke_protoc "${args[@]}" "$proto"
}

# Generates messages by invoking protoc with the Swift plugin.
# Parameters:
# - $1: .proto file
# - $2: proto path
# - $3: output path
# - $4 onwards: options to forward to the plugin
function generate_message {
  local proto=$1
  local args=("--plugin=$protoc_gen_swift" "--proto_path=$2" "--swift_out=$3")

  for option in "${@:4}"; do
    args+=("--swift_opt=$option")
  done

  invoke_protoc "${args[@]}" "$proto"
}

function invoke_protoc {
  # Setting -x when running the script produces a lot of output, instead boil
  # just echo out the protoc invocations.
  echo "$protoc" "$@"
  "$protoc" "$@"
}

#- DETAILED ERROR -------------------------------------------------------------

function generate_rpc_error_details {
  local protos output

  protos=(
    "$here/upstream/google/rpc/status.proto"
    "$here/upstream/google/rpc/code.proto"
    "$here/upstream/google/rpc/error_details.proto"
  )
  output="$root/Sources/GRPCProtobuf/Errors/Generated"

  for proto in "${protos[@]}"; do
    generate_message "$proto" "$(dirname "$proto")" "$output" "Visibility=Internal" "UseAccessLevelOnImports=true"
  done
}

#- DETAILED ERROR Tests -------------------------------------------------------

function generate_error_service {
  local proto output
  proto="$here/local/error-service.proto"
  output="$root/Tests/GRPCProtobufTests/Errors/Generated"

  generate_message "$proto" "$(dirname "$proto")" "$output" "Visibility=Internal" "UseAccessLevelOnImports=true"
  generate_grpc "$proto" "$(dirname "$proto")" "$output" "Visibility=Internal" "UseAccessLevelOnImports=true" "Availability=gRPCSwiftProtobuf 2.0"
}

#- DESCRIPTOR SETS ------------------------------------------------------------

function generate_test_service_descriptor_set {
  local proto proto_path output
  proto="$here/local/test-service.proto"
  proto_path="$(dirname "$proto")"
  output="$root/Tests/GRPCProtobufCodeGenTests/Generated/test-service.pb"

  invoke_protoc --descriptor_set_out="$output" "$proto" -I "$proto_path" \
    --include_imports \
    --include_source_info
}

function generate_foo_service_descriptor_set {
  local proto proto_path output
  proto="$here/local/foo-service.proto"
  proto_path="$(dirname "$proto")"
  output="$root/Tests/GRPCProtobufCodeGenTests/Generated/foo-service.pb"

  invoke_protoc --descriptor_set_out="$output" "$proto" -I "$proto_path" \
    --include_source_info \
    --include_imports
}

function generate_foo_messages_descriptor_set {
  local proto proto_path output
  proto="$here/local/foo-messages.proto"
  proto_path="$(dirname "$proto")"
  output="$root/Tests/GRPCProtobufCodeGenTests/Generated/foo-messages.pb"

  invoke_protoc --descriptor_set_out="$output" "$proto" -I "$proto_path" \
    --include_source_info \
    --include_imports
}

function generate_bar_service_descriptor_set {
  local proto proto_path output
  proto="$here/local/bar-service.proto"
  proto_path="$(dirname "$proto")"
  output="$root/Tests/GRPCProtobufCodeGenTests/Generated/bar-service.pb"

  invoke_protoc --descriptor_set_out="$output" "$proto" -I "$proto_path" \
    --include_source_info \
    --include_imports
}

function generate_wkt_service_descriptor_set {
  local proto proto_path output
  proto="$here/local/wkt-service.proto"
  proto_path="$(dirname "$proto")"
  output="$root/Tests/GRPCProtobufCodeGenTests/Generated/wkt-service.pb"

  invoke_protoc --descriptor_set_out="$output" "$proto" -I "$proto_path" \
    --include_source_info \
    --include_imports
}

#------------------------------------------------------------------------------

# Detailed error model
generate_rpc_error_details

# Service for testing error details
generate_error_service

# Descriptor sets for tests
generate_test_service_descriptor_set
generate_foo_service_descriptor_set
generate_foo_messages_descriptor_set
generate_bar_service_descriptor_set
generate_wkt_service_descriptor_set
