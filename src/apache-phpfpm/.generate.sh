#!/bin/bash
# Generate Apache PHP-FPM Dockerfiles
# Sources config.sh for PHP versions and docker registry settings
# Usage: apache-phpfpm/.generate.sh

set -e

SCRIPTDIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPTDIR"
source ../../build/generate-lib.sh
source ../../build/config.sh

TEMPLATE="Dockerfile-template"
check_template "$TEMPLATE" || exit 1

log_info "Generating Apache PHP-FPM Dockerfiles..."
log_info "  PHP versions: ${PHP_VERSIONS[*]}"
log_info "  Docker registry: ${DOCKER_REGISTRY_PREFIX}"

# Generate individual version Dockerfiles
for version in "${PHP_VERSIONS[@]}"; do
    # Normalize version: 5.6 -> 56, 7.2 -> 72, etc.
    normalized_version="${version//.}"
    
    # Ubuntu variant
    output_ubu="Dockerfile-${normalized_version}-ubu"
    log_info "  Apache PHP $version (Ubuntu)"
    process_template "$TEMPLATE" "$output_ubu" "PHPVERSION=$version" "VERSION=$version"
    
    # Replace registry references
    safe_sed "eilandert/php-fpm:" "${DOCKER_REGISTRY_PREFIX}/${IMAGE_PREFIX_PHP_FPM}:" "$output_ubu"
    
    # Debian variant
    debian_output="Dockerfile-${normalized_version}-deb"
    cp "$output_ubu" "$debian_output"
    safe_sed "${DOCKER_REGISTRY_PREFIX}/${IMAGE_PREFIX_PHP_FPM}:" "${DOCKER_REGISTRY_PREFIX}/${IMAGE_PREFIX_PHP_FPM}:deb-" "$debian_output"
done

# Generate multi-PHP variant
log_info "  Apache PHP multi"
multi_ubu="Dockerfile-multi-ubu"
process_template "$TEMPLATE" "$multi_ubu" "PHPVERSION=multi" "VERSION=multi"

# Replace registry references
safe_sed "eilandert/php-fpm:" "${DOCKER_REGISTRY_PREFIX}/${IMAGE_PREFIX_PHP_FPM}:" "$multi_ubu"

# Clean up apache-specific directives for multi (only need one version's apache config)
safe_sed "libapache2-mod-php" "" "$multi_ubu"
safe_sed "a2enconf php" "" "$multi_ubu"
safe_sed "a2dismod php" "" "$multi_ubu"

# Create debian variant
multi_deb="Dockerfile-multi-deb"
cp "$multi_ubu" "$multi_deb"
safe_sed "${DOCKER_REGISTRY_PREFIX}/${IMAGE_PREFIX_PHP_FPM}:" "${DOCKER_REGISTRY_PREFIX}/${IMAGE_PREFIX_PHP_FPM}:deb-" "$multi_deb"

log_info "✓ Apache PHP-FPM Dockerfiles generated (${#PHP_VERSIONS[@]} versions + multi)"
