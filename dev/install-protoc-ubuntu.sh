#!/bin/bash
## Copyright 2026, gRPC Authors All rights reserved.
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

PROTOC_VERSION=${PROTOC_VERSION:-33.5}
INSTALL_DIR=${INSTALL_DIR:-/usr/local}

echo "Installing protoc ${PROTOC_VERSION} on Ubuntu/Debian..."

# Install dependencies using apt-get
apt-get update -y -q
apt-get install -y -q curl unzip

# Download and install protoc for Linux x86_64
curl -LO "https://github.com/protocolbuffers/protobuf/releases/download/v${PROTOC_VERSION}/protoc-${PROTOC_VERSION}-linux-x86_64.zip"
unzip "protoc-${PROTOC_VERSION}-linux-x86_64.zip" -d "${INSTALL_DIR}"
rm "protoc-${PROTOC_VERSION}-linux-x86_64.zip"

# Verify installation
protoc --version
