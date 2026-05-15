#!/bin/bash
# Generate base image Dockerfiles
# Sources config.sh for Ubuntu/Debian versions and docker registry settings
# Usage: base/.generate.sh

set -e

SCRIPTDIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPTDIR"
source ../../build/generate-lib.sh
source ../../build/config.sh

TEMPLATE="Dockerfile-template"
check_template "$TEMPLATE" || exit 1

log_info "Generating base image Dockerfiles..."
log_info "Using distros: UBUNTULTS=$UBUNTULTS DEBIANSTABLE=$DEBIANSTABLE"
log_info "Using tags: UBUNTU_BASE_TAG=$UBUNTU_BASE_TAG DEBIAN_BASE_TAG=$DEBIAN_BASE_TAG"
log_info "Using registry: $DOCKER_REGISTRY_PREFIX"

# Define variants: variant_name FROM DIST
# Only generate primary Ubuntu and Debian versions from config
declare -A VARIANTS=(
    [ubuntu-base]="ubuntu:${UBUNTULTS}|${UBUNTULTS}"
    [debian-base]="debian:${DEBIANSTABLE}-slim|${DEBIANSTABLE}"
)

log_info "Generating ${#VARIANTS[@]} base image variants"

for variant in "${!VARIANTS[@]}"; do
    IFS='|' read -r from dist <<< "${VARIANTS[$variant]}"
    output="Dockerfile-${variant}"

    log_info "  $variant: FROM=$from DIST=$dist"
    process_template "$TEMPLATE" "$output" "TEMPLATE1=$from" "TEMPLATE2=$dist"
done

log_info "✓ Base images generated"
