#!/bin/bash
# Generate Nginx Dockerfiles for multiple PHP versions
# Sources config.sh for PHP versions and docker registry settings
# Includes ubuntu and debian variants
# Usage: nginx/.generate.sh

set -e

SCRIPTDIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPTDIR"
source ../../build/generate-lib.sh
source ../../build/config.sh

TEMPLATE="Dockerfile.template"
check_template "$TEMPLATE" || exit 1

log_info "Generating Nginx Dockerfiles..."
log_info "  PHP versions: ${PHP_VERSIONS[*]}"
log_info "  Docker registry: ${DOCKER_REGISTRY_PREFIX}"

# Multi-PHP
log_info "  Nginx multi (ubuntu)"
process_template "$TEMPLATE" "Dockerfile-multi-ubu" \
    "FROM=${DOCKER_REGISTRY_PREFIX}/${IMAGE_PREFIX_PHP_FPM}:multi" \
    "APT_UPGRADE=true"

log_info "  Nginx multi (debian)"
process_template "$TEMPLATE" "Dockerfile-multi-deb" \
    "FROM=${DOCKER_REGISTRY_PREFIX}/${IMAGE_PREFIX_PHP_FPM}:deb-multi" \
    "APT_UPGRADE=true"

# Base: ubuntu rolling (no PHP)
log_info "  Nginx base (ubuntu)"
process_template "$TEMPLATE" "Dockerfile-ubu" \
    "FROM=${DOCKER_REGISTRY_PREFIX}/${IMAGE_PREFIX_UBUNTU_BASE}:${UBUNTU_BASE_TAG}" \
    "APT_UPGRADE=apt-get -y upgrade"

log_info "  Nginx base (debian)"
process_template "$TEMPLATE" "Dockerfile-deb" \
    "FROM=${DOCKER_REGISTRY_PREFIX}/${IMAGE_PREFIX_DEBIAN_BASE}:${DEBIAN_BASE_TAG}" \
    "APT_UPGRADE=apt-get -y upgrade"

# PHP versions
for version in "${PHP_VERSIONS[@]}"; do
    # Normalize version: remove dots (5.6 -> 56, 7.4 -> 74, etc.)
    normalized_version="${version//.}"

    ubuntu_output="Dockerfile-php${normalized_version}-ubu"
    debian_output="Dockerfile-php${normalized_version}-deb"

    log_info "  Nginx PHP $version (ubuntu)"
    process_template "$TEMPLATE" "$ubuntu_output" \
        "FROM=${DOCKER_REGISTRY_PREFIX}/${IMAGE_PREFIX_PHP_FPM}:${version}" \
        "APT_UPGRADE=apt-get -y upgrade"

    log_info "  Nginx PHP $version (debian)"
    process_template "$TEMPLATE" "$debian_output" \
        "FROM=${DOCKER_REGISTRY_PREFIX}/${IMAGE_PREFIX_PHP_FPM}:deb-${version}" \
        "APT_UPGRADE=apt-get -y upgrade"
done

log_info "✓ Nginx Dockerfiles generated"
