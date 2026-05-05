#!/bin/bash
# Generate Nginx Dockerfiles for multiple PHP versions
# Includes ubuntu and debian variants
# Usage: nginx/.generate.sh

set -e

SCRIPTDIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPTDIR"
source ../generate-lib.sh

TEMPLATE="Dockerfile.template"
check_template "$TEMPLATE" || exit 1

log_info "Generating Nginx Dockerfiles..."

# Base: ubuntu rolling (no PHP)
log_info "  Nginx base (ubuntu)"
process_template "$TEMPLATE" "Dockerfile" "FROM=eilandert/ubuntu-base:rolling"

log_info "  Nginx base (debian)"
process_template "$TEMPLATE" "Dockerfile-debian" "FROM=eilandert/debian-base:stable"

# Multi-PHP
log_info "  Nginx multi (ubuntu)"
process_template "$TEMPLATE" "Dockerfile-multi" "FROM=eilandert/php-fpm:multi"

log_info "  Nginx multi (debian)"
process_template "$TEMPLATE" "Dockerfile-multidebian" "FROM=eilandert/php-fpm:deb-multi"

# PHP versions
declare -a VERSIONS=(5.6 7.2 7.4 8.0 8.1 8.2 8.3 8.4)

for version in "${VERSIONS[@]}"; do
    ubuntu_output="Dockerfile-php${version}"
    debian_output="Dockerfile-php${version}debian"
    
    log_info "  Nginx PHP $version (ubuntu)"
    process_template "$TEMPLATE" "$ubuntu_output" "FROM=eilandert/php-fpm:${version}"
    
    log_info "  Nginx PHP $version (debian)"
    process_template "$TEMPLATE" "$debian_output" "FROM=eilandert/php-fpm:deb-${version}"
done

log_info "✓ Nginx Dockerfiles generated"
