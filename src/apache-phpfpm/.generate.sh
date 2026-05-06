#!/bin/bash
# Generate Apache PHP-FPM Dockerfiles
# Usage: apache-phpfpm/.generate.sh

set -e

SCRIPTDIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPTDIR"
source ../../build/generate-lib.sh

TEMPLATE="Dockerfile-template"
check_template "$TEMPLATE" || exit 1

log_info "Generating Apache PHP-FPM Dockerfiles..."

declare -a VERSIONS=(5.6 7.2 7.4 8.0 8.1 8.2 8.3 8.4 8.5)

# Generate individual version Dockerfiles
for version in "${VERSIONS[@]}"; do
    # Normalize version: 5.6 -> 56, 7.2 -> 72, etc.
    normalized_version="${version//.}"
    
    # Ubuntu variant
    output_ubu="Dockerfile-${normalized_version}-ubu"
    log_info "  Apache PHP $version (Ubuntu)"
    process_template "$TEMPLATE" "$output_ubu" "PHPVERSION=$version"
    
    # Debian variant
    debian_output="Dockerfile-${normalized_version}-deb"
    cp "$output_ubu" "$debian_output"
    safe_sed "eilandert/php-fpm:" "eilandert/php-fpm:deb-" "$debian_output"
done

# Generate multi-PHP variant
log_info "  Apache PHP multi"
multi_ubu="Dockerfile-multi-ubu"
process_template "$TEMPLATE" "$multi_ubu" "PHPVERSION=multi"

# Clean up apache-specific directives for multi (only need one version's apache config)
safe_sed "libapache2-mod-php" "" "$multi_ubu"
safe_sed "a2enconf php" "" "$multi_ubu"
safe_sed "a2dismod php" "" "$multi_ubu"

# Create debian variant
multi_deb="Dockerfile-multi-deb"
cp "$multi_ubu" "$multi_deb"
safe_sed "eilandert/php-fpm:" "eilandert/php-fpm:deb-" "$multi_deb"

log_info "✓ Apache PHP-FPM Dockerfiles generated (${#VERSIONS[@]} versions + multi)"
