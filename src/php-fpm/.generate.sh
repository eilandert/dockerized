#!/bin/bash
# Generate PHP-FPM Dockerfiles for multiple PHP versions
# Sources config.sh for PHP versions and docker registry settings
# Includes ubuntu and debian variants
# Usage: php-fpm/.generate.sh

set -e

SCRIPTDIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPTDIR"
source ../../build/generate-lib.sh
source ../../build/config.sh

TEMPLATE_PHP="Dockerfile-template.php"
TEMPLATE_HEADER="Dockerfile-template.header"
TEMPLATE_FOOTER="Dockerfile-template.footer"

check_template "$TEMPLATE_PHP" || exit 1
check_template "$TEMPLATE_HEADER" || exit 1
check_template "$TEMPLATE_FOOTER" || exit 1

log_info "Generating PHP-FPM Dockerfiles..."
log_info "  PHP versions: ${PHP_VERSIONS[*]}"
log_info "  Docker registry: ${DOCKER_REGISTRY_PREFIX}"

# Build removal markers array from config
declare -a REMOVE_MARKERS_ARRAY=()
for version in "${PHP_VERSIONS[@]}"; do
    markers="${PHP_REMOVAL_MARKERS[$version]}"
    if [[ -n "$markers" ]]; then
        REMOVE_MARKERS_ARRAY+=("$version:$markers")
    else
        REMOVE_MARKERS_ARRAY+=("$version:")
    fi
done

# Step 1: Generate individual version Dockerfiles
log_info "  Generating individual PHP versions..."
temp_files=()

for version in "${PHP_VERSIONS[@]}"; do
    temp="Dockerfile-template.generated.php${version}"
    log_info "    PHP $version"

    process_template "$TEMPLATE_PHP" "$temp" "PHPVERSION=$version"

    # Remove version-specific marker lines
    for marker_spec in "${REMOVE_MARKERS_ARRAY[@]}"; do
        spec_version="${marker_spec%%:*}"
        markers="${marker_spec#*:}"

        if [[ "$spec_version" == "$version" && -n "$markers" ]]; then
            IFS=',' read -ra marker_array <<< "$markers"
            for marker in "${marker_array[@]}"; do
                remove_markers "$temp" "#$marker#"
            done
        fi
    done

    temp_files+=("$temp")
done

# Step 2: Build individual Dockerfiles from header + version + footer
log_info "  Building complete Dockerfiles..."
for version in "${PHP_VERSIONS[@]}"; do
    # Normalize version: remove dots (5.6 -> 56, 7.4 -> 74, etc.)
    normalized_version="${version//.}"

    temp="Dockerfile-template.generated.php${version}"
    ubuntu_output="Dockerfile-${normalized_version}-ubu"
    debian_output="Dockerfile-${normalized_version}-deb"

    log_info "    $ubuntu_output"
    cat "$TEMPLATE_HEADER" "$temp" "$TEMPLATE_FOOTER" > "$ubuntu_output"

    # Set version in output
    safe_sed "#PHPVERSION#" "$version" "$ubuntu_output"

    # Replace registry/tag with config values
    safe_sed "eilandert/ubuntu-base:rolling" "${DOCKER_REGISTRY_PREFIX}/${IMAGE_PREFIX_UBUNTU_BASE}:${UBUNTU_BASE_TAG}" "$ubuntu_output"

    # Comment out the rm -rf for this PHP version (keep all versions in single Dockerfile potential)
    safe_sed "rm -rf /etc/php/${version}" "#rm -rf /etc/php/${version}" "$ubuntu_output"

    # Create debian variant
    cp "$ubuntu_output" "$debian_output"
    safe_sed "${DOCKER_REGISTRY_PREFIX}/${IMAGE_PREFIX_UBUNTU_BASE}:${UBUNTU_BASE_TAG}" "${DOCKER_REGISTRY_PREFIX}/${IMAGE_PREFIX_DEBIAN_BASE}:${DEBIAN_BASE_TAG}" "$debian_output"

    # Remove unsupported packages from PHP 5.6 debian
    if [[ "$version" == "5.6" ]]; then
        sed -i '/zstd/d' "$ubuntu_output"
        sed -i '/snuffleupagus/d' "$ubuntu_output"
        sed -i '/zstd/d' "$debian_output"
        sed -i '/snuffleupagus/d' "$debian_output"
    fi
    # Remove packages not available in PHP 8.5
    if [[ "$version" == "8.5" ]]; then
        sed -i '/opcache/d' "$ubuntu_output"
        sed -i '/opcache/d' "$debian_output"
    fi
done

# Step 3: Build multi-PHP Dockerfile
log_info "  Building multi-PHP variant..."
multi_output="Dockerfile-multi-ubu"
cat "$TEMPLATE_HEADER" > "$multi_output"
for version in "${PHP_VERSIONS[@]}"; do
    temp="Dockerfile-template.generated.php${version}"
    cat "$temp" >> "$multi_output"
done
cat "$TEMPLATE_FOOTER" >> "$multi_output"

safe_sed "#PHPVERSION#" "MULTI" "$multi_output"
safe_sed "MODE=FPM" "MODE=MULTI" "$multi_output"
safe_sed "rm -rf /etc/php" "#rm -rf /etc/php" "$multi_output"
safe_sed "eilandert/ubuntu-base:rolling" "${DOCKER_REGISTRY_PREFIX}/${IMAGE_PREFIX_UBUNTU_BASE}:${UBUNTU_BASE_TAG}" "$multi_output"

# Create debian variant
multi_debian="Dockerfile-multi-deb"
cp "$multi_output" "$multi_debian"
safe_sed "${DOCKER_REGISTRY_PREFIX}/${IMAGE_PREFIX_UBUNTU_BASE}:${UBUNTU_BASE_TAG}" "${DOCKER_REGISTRY_PREFIX}/${IMAGE_PREFIX_DEBIAN_BASE}:${DEBIAN_BASE_TAG}" "$multi_debian"

# Step 4: Clean up temp files
rm -f Dockerfile-template.generated.*

log_info "✓ PHP-FPM Dockerfiles generated (${#PHP_VERSIONS[@]} PHP versions + multi + debian variants)"
