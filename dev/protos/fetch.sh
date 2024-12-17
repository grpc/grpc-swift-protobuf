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
upstream="$here/upstream"

# Create a temporary directory for the repo checkouts.
checkouts="$(mktemp -d)"

# Clone the google protos into the staging area.
git clone --depth 1 https://github.com/googleapis/googleapis.git "$checkouts/googleapis"

# Remove the old protos.
rm -rf "$upstream"

# Copy over the googleapis protos.
mkdir -p "$upstream/google/rpc"
cp -rp "$checkouts/googleapis/google/rpc/error_details.proto" "$upstream/google/rpc/error_details.proto"
cp -rp "$checkouts/googleapis/google/rpc/code.proto" "$upstream/google/rpc/code.proto"
cp -rp "$checkouts/googleapis/google/rpc/status.proto" "$upstream/google/rpc/status.proto"
