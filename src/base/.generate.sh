#!/bin/bash
# Generate base image Dockerfiles
# Usage: base/.generate.sh
# Sources config.sh for UBUNTULTS and DEBIANSTABLE versions

set -e

SCRIPTDIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPTDIR"
source ../../build/generate-lib.sh
source ../../build/config.sh

TEMPLATE="Dockerfile-template"
check_template "$TEMPLATE" || exit 1

log_info "Generating base image Dockerfiles..."
log_info "Using config: UBUNTULTS=$UBUNTULTS DEBIANSTABLE=$DEBIANSTABLE"

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
