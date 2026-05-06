#!/bin/bash
# Docker build orchestration wrapper
# Delegates to build/buildx-sequential.sh (sequential by default)
# For parallel builds, call: ./build/buildx.sh directly

SCRIPTDIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPTDIR"

exec ./build/buildx-sequential.sh "$@"
