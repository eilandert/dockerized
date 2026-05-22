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

# Step 1: Generate individual version Dockerfiles
#
# For each PHP version we render the .php template and then, for every
# #removedinphpXY# marker, either strip the line (if this PHP version is
# >= XY, package no longer exists) or strip just the marker tag and keep
# the package line. Previously the marker was only handled for the exact
# version named in a map, which left markers in place for 8.x — apt then
# saw "#removedinphp80#php8.4-json" as a package name and the leading "#"
# turned the rest of the apt-get install line into a shell comment, so
# every package after the first marker silently dropped out. See audit.
# Strip a list of extensions from a PHP package list for a given version.
# Usage: strip_exts <file> <php-version> <ext1> <ext2> ...
# Matches "php<ver>-<ext>" with word boundary so php8.4-memcache doesn't also
# kill php8.4-memcached.
strip_exts() {
    local file="$1" version="$2"
    shift 2
    local ext
    for ext in "$@"; do
        sed -i -E "/[[:space:]]php${version}-${ext}([[:space:]\\\\]|$)/d" "$file"
    done
}

# Ubuntu-only strips: ondrej-noble lacks PECL extras + 8.4+ imap/pspell.
apply_ubuntu_strips() {
    local file="$1" version="$2"
    strip_exts "$file" "$version" "${PHP_UBUNTU_MISSING_EXTS[@]}"
    local ext cutoff
    for ext in "${!PHP_UBUNTU_MISSING_CUTOFF[@]}"; do
        cutoff="${PHP_UBUNTU_MISSING_CUTOFF[$ext]}"
        if version_ge "$version" "$cutoff"; then
            strip_exts "$file" "$version" "$ext"
        fi
    done
}

log_info "  Generating individual PHP versions..."
temp_files=()

for version in "${PHP_VERSIONS[@]}"; do
    temp="Dockerfile-template.generated.php${version}"
    log_info "    PHP $version"

    process_template "$TEMPLATE_PHP" "$temp" "PHPVERSION=$version"

    for marker in "${!PHP_REMOVAL_CUTOFF[@]}"; do
        strip_marker_for_version "$temp" "$version" "$marker" "${PHP_REMOVAL_CUTOFF[$marker]}"
    done

    # Per-version mirror gaps that apply to BOTH distros (so they land on
    # the temp BEFORE concat into the multi Dockerfile).
    if [[ -n "${PHP_VERSION_MISSING_EXTS[$version]:-}" ]]; then
        # shellcheck disable=SC2086  # intentional word splitting
        strip_exts "$temp" "$version" ${PHP_VERSION_MISSING_EXTS[$version]}
    fi

    # Assert no markers leaked through — generator bug if they did.
    # Only match the actual #removedinphpXY# tag form to avoid false hits
    # on the explanatory comment header inside the template.
    if grep -qE '#removedinphp[0-9]+#' "$temp"; then
        log_error "    Leftover #removedinphp...# marker in $temp"
        grep -nE '#removedinphp[0-9]+#' "$temp" >&2
        exit 1
    fi

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

    # Set both #PHPVERSION# (env var) and #VERSION# (OCI image.version label)
    safe_sed "#PHPVERSION#" "$version" "$ubuntu_output"
    safe_sed "#VERSION#"    "$version" "$ubuntu_output"

    # Replace registry/tag with config values
    safe_sed "eilandert/ubuntu-base:rolling" "${DOCKER_REGISTRY_PREFIX}/${IMAGE_PREFIX_UBUNTU_BASE}:${UBUNTU_BASE_TAG}" "$ubuntu_output"

    # Comment out the rm -rf for this PHP version (keep all versions in single Dockerfile potential)
    safe_sed "rm -rf /etc/php/${version}" "#rm -rf /etc/php/${version}" "$ubuntu_output"

    # Debian variant is created from the (still-complete) ubuntu_output BEFORE
    # we apply Ubuntu-only strips, so Debian keeps its PECL/snuffleupagus/imap/
    # pspell packages (the trixie mirror has them).
    cp "$ubuntu_output" "$debian_output"
    safe_sed "${DOCKER_REGISTRY_PREFIX}/${IMAGE_PREFIX_UBUNTU_BASE}:${UBUNTU_BASE_TAG}" "${DOCKER_REGISTRY_PREFIX}/${IMAGE_PREFIX_DEBIAN_BASE}:${DEBIAN_BASE_TAG}" "$debian_output"

    # Ubuntu-only: strip packages absent from the ondrej-noble mirror.
    apply_ubuntu_strips "$ubuntu_output" "$version"
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
safe_sed "#VERSION#"    "multi" "$multi_output"
safe_sed "MODE=FPM" "MODE=MULTI" "$multi_output"
safe_sed "rm -rf /etc/php" "#rm -rf /etc/php" "$multi_output"
safe_sed "eilandert/ubuntu-base:rolling" "${DOCKER_REGISTRY_PREFIX}/${IMAGE_PREFIX_UBUNTU_BASE}:${UBUNTU_BASE_TAG}" "$multi_output"

# Create debian variant from the still-complete multi BEFORE Ubuntu-only strips.
multi_debian="Dockerfile-multi-deb"
cp "$multi_output" "$multi_debian"
safe_sed "${DOCKER_REGISTRY_PREFIX}/${IMAGE_PREFIX_UBUNTU_BASE}:${UBUNTU_BASE_TAG}" "${DOCKER_REGISTRY_PREFIX}/${IMAGE_PREFIX_DEBIAN_BASE}:${DEBIAN_BASE_TAG}" "$multi_debian"

# Ubuntu-only strips: apply per PHP version so missing packages disappear
# from each chunk of the multi-distro Dockerfile.
for version in "${PHP_VERSIONS[@]}"; do
    apply_ubuntu_strips "$multi_output" "$version"
done

# Step 4: Clean up temp files
rm -f Dockerfile-template.generated.*

log_info "✓ PHP-FPM Dockerfiles generated (${#PHP_VERSIONS[@]} PHP versions + multi + debian variants)"
