#!/bin/bash
# Generate base image Dockerfiles
# Usage: base/.generate.sh

set -e

SCRIPTDIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPTDIR"
source ../../build/generate-lib.sh

TEMPLATE="Dockerfile-template"
check_template "$TEMPLATE" || exit 1

log_info "Generating base image Dockerfiles..."

# Define variants: variant_name FROM DIST
declare -A VARIANTS=(
    [devel]="ubuntu:devel|devel"
    [rolling]="ubuntu:noble|noble"
    [noble]="ubuntu:noble|noble"
    [jammy]="ubuntu:jammy|jammy"
    [focal]="ubuntu:focal|focal"
    [bionic]="ubuntu:bionic|bionic"
    [xenial]="ubuntu:xenial|xenial"
    [trusty]="ubuntu:trusty|trusty"
    [resolute]="ubuntu:resolute|resolute"
    [trixie]="debian:trixie-slim|trixie"
    [bookworm]="debian:bookworm-slim|bookworm"
    [bullseye]="debian:bullseye-slim|bullseye"
    [buster]="debian:buster-slim|buster"
    [stretch]="debian:stretch-slim|stretch"
    [jessie]="debian:jessie-slim|jessie"
)

for variant in "${!VARIANTS[@]}"; do
    IFS='|' read -r from dist <<< "${VARIANTS[$variant]}"
    output="Dockerfile-${variant}"

    log_info "  $variant: FROM=$from DIST=$dist"
    process_template "$TEMPLATE" "$output" "TEMPLATE1=$from" "TEMPLATE2=$dist"
done

log_info "✓ Base images generated"
