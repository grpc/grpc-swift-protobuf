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

source_dir=$(pwd)
pluginTests="${source_dir}/IntegrationTests/PluginTests"

for dir in "$pluginTests"/test_*/ ; do
  if [[ -f "$dir/Package.swift" ]]; then
    pluginTest=$(basename "$dir")
    log "Building '$pluginTest' plugin test"

    if ! build_output=$(swift build --package-path "$dir" 2>&1); then
      # Only print the build output on failure.
      echo "$build_output"
      fatal "Build failed for '$pluginTest'"
    else
      log "Build succeeded for '$pluginTest'"
    fi
  fi
done
