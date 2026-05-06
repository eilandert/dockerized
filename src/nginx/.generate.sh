#!/bin/bash
# Generate Nginx Dockerfiles for multiple PHP versions
# Includes ubuntu and debian variants
# Usage: nginx/.generate.sh

set -e

SCRIPTDIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPTDIR"
source ../../build/generate-lib.sh

TEMPLATE="Dockerfile.template"
check_template "$TEMPLATE" || exit 1

log_info "Generating Nginx Dockerfiles..."

# Multi-PHP
log_info "  Nginx multi (ubuntu)"
process_template "$TEMPLATE" "Dockerfile-multi-ubu" "FROM=eilandert/php-fpm:multi"

log_info "  Nginx multi (debian)"
process_template "$TEMPLATE" "Dockerfile-multi-deb" "FROM=eilandert/php-fpm:deb-multi"

# Base: ubuntu rolling (no PHP)
log_info "  Nginx base (ubuntu)"
process_template "$TEMPLATE" "Dockerfile-ubu" "FROM=eilandert/ubuntu-base:rolling"

log_info "  Nginx base (debian)"
process_template "$TEMPLATE" "Dockerfile-deb" "FROM=eilandert/debian-base:stable"

# PHP versions
declare -a VERSIONS=(5.6 7.2 7.4 8.0 8.1 8.2 8.3 8.4 8.5)

for version in "${VERSIONS[@]}"; do
    # Normalize version: remove dots (5.6 -> 56, 7.4 -> 74, etc.)
    normalized_version="${version//.}"
    
    ubuntu_output="Dockerfile-php${normalized_version}-ubu"
    debian_output="Dockerfile-php${normalized_version}-deb"
    
    log_info "  Nginx PHP $version (ubuntu)"
    process_template "$TEMPLATE" "$ubuntu_output" "FROM=eilandert/php-fpm:${version}"
    
    log_info "  Nginx PHP $version (debian)"
    process_template "$TEMPLATE" "$debian_output" "FROM=eilandert/php-fpm:deb-${version}"
done

log_info "✓ Nginx Dockerfiles generated"
