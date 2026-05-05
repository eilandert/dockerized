#!/bin/bash
# Dockerfile generation wrapper
# Delegates to build/generate.sh with all arguments

SCRIPTDIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPTDIR"

exec ./build/generate.sh "$@"
