#!/bin/bash
# Docker build orchestration wrapper.
# Delegates to build/buildx-sequential.sh — the only orchestrator.

SCRIPTDIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPTDIR"

exec ./build/buildx-sequential.sh "$@"
