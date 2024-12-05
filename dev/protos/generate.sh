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

function invoke_protoc {
  # Setting -x when running the script produces a lot of output, instead boil
  # just echo out the protoc invocations.
  echo "$protoc" "$@"
  "$protoc" "$@"
}

#- DESCRIPTOR SETS ------------------------------------------------------------

function generate_test_service_descriptor_set {
  local proto proto_path output
  proto="$here/local/test-service.proto"
  proto_path="$(dirname "$proto")"
  output="$root/Tests/GRPCProtobufCodeGenTests/Generated/test-service.pb"

  invoke_protoc --descriptor_set_out="$output" "$proto" -I "$proto_path" --include_source_info
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

# Descriptor sets
generate_test_service_descriptor_set
generate_foo_service_descriptor_set
generate_bar_service_descriptor_set
generate_wkt_service_descriptor_set
