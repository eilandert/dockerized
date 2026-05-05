#!/bin/bash
# Generate Apache PHP-FPM Dockerfiles
# Usage: apache-phpfpm/.generate.sh

set -e

SCRIPTDIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPTDIR"
source ../generate-lib.sh

TEMPLATE="Dockerfile-template"
check_template "$TEMPLATE" || exit 1

log_info "Generating Apache PHP-FPM Dockerfiles..."

declare -a VERSIONS=(5.6 7.2 7.4 8.0 8.1 8.2 8.3 8.4)

# Generate individual version Dockerfiles
for version in "${VERSIONS[@]}"; do
    output="Dockerfile-${version}"
    log_info "  Apache PHP $version"
    process_template "$TEMPLATE" "$output" "PHPVERSION=$version"
    
    # Create debian variant
    debian_output="Dockerfile-${version}debian"
    cp "$output" "$debian_output"
    safe_sed "eilandert/php-fpm:" "eilandert/php-fpm:deb-" "$debian_output"
done

# Generate multi-PHP variant
log_info "  Apache PHP multi"
multi_output="Dockerfile-multi"
process_template "$TEMPLATE" "$multi_output" "PHPVERSION=multi"

# Clean up apache-specific directives for multi (only need one version's apache config)
safe_sed "libapache2-mod-php" "" "$multi_output"
safe_sed "a2enconf php" "" "$multi_output"
safe_sed "a2dismod php" "" "$multi_output"

# Create debian variant
multi_debian="Dockerfile-multidebian"
cp "$multi_output" "$multi_debian"
safe_sed "eilandert/php-fpm:" "eilandert/php-fpm:deb-" "$multi_debian"

log_info "✓ Apache PHP-FPM Dockerfiles generated (${#VERSIONS[@]} versions + multi)"
