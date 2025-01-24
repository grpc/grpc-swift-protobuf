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

if [[ -n ${GITHUB_ACTIONS:=""} ]]; then
    # we will have been piped to bash and won't know the location of the script
    echo "Running in GitHub Actions"
    source_directory="$(pwd)"
else
    here="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
    source_directory="$(readlink -f "${here}/..")"
fi
tests_directory="${PLUGIN_TESTS_OUTPUT_DIRECTORY:=$(mktemp -d)}"

PLUGIN_TESTS_OUTPUT_DIRECTORY="$tests_directory" "${source_directory}/dev/setup-plugin-tests.sh"
PLUGIN_TESTS_DIRECTORY="$tests_directory" "${source_directory}/dev/execute-plugin-tests.sh"
