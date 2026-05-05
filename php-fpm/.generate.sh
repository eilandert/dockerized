#!/bin/bash
# Generate PHP-FPM Dockerfiles for multiple PHP versions
# Includes ubuntu and debian variants
# Usage: php-fpm/.generate.sh

set -e

SCRIPTDIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPTDIR"
source ../generate-lib.sh

TEMPLATE_PHP="Dockerfile-template.php"
TEMPLATE_HEADER="Dockerfile-template.header"
TEMPLATE_FOOTER="Dockerfile-template.footer"

check_template "$TEMPLATE_PHP" || exit 1
check_template "$TEMPLATE_HEADER" || exit 1
check_template "$TEMPLATE_FOOTER" || exit 1

log_info "Generating PHP-FPM Dockerfiles..."

declare -a VERSIONS=(5.6 7.2 7.4 8.0 8.1 8.2 8.3 8.4)
declare -a REMOVE_MARKERS=(
    "5.6:removedinphp72,removedinphp74,removedinphp80"
    "7.2:removedinphp74,removedinphp80"
    "7.4:removedinphp80"
    "8.0:"
    "8.1:"
    "8.2:"
    "8.3:"
    "8.4:"
)

# Step 1: Generate individual version Dockerfiles
log_info "  Generating individual PHP versions..."
temp_files=()

for version in "${VERSIONS[@]}"; do
    temp="Dockerfile-template.generated.php${version}"
    log_info "    PHP $version"
    
    process_template "$TEMPLATE_PHP" "$temp" "PHPVERSION=$version"
    
    # Remove version-specific marker lines
    for marker_spec in "${REMOVE_MARKERS[@]}"; do
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
for version in "${VERSIONS[@]}"; do
    temp="Dockerfile-template.generated.php${version}"
    output="Dockerfile-${version}"
    
    log_info "    $output"
    cat "$TEMPLATE_HEADER" "$temp" "$TEMPLATE_FOOTER" > "$output"
    
    # Set version in output
    safe_sed "#PHPVERSION#" "$version" "$output"
    
    # Comment out the rm -rf for this PHP version (keep all versions in single Dockerfile potential)
    safe_sed "rm -rf /etc/php/${version}" "#rm -rf /etc/php/${version}" "$output"
    
    # Create debian variant
    debian_output="Dockerfile-${version}debian"
    cp "$output" "$debian_output"
    safe_sed "eilandert/ubuntu-base:rolling" "eilandert/debian-base:stable" "$debian_output"
    
    # Remove unsupported packages from PHP 5.6 debian
    if [[ "$version" == "5.6" ]]; then
        sed -i '/zstd/d' "$output"
        sed -i '/snuffleupagus/d' "$output"
        sed -i '/zstd/d' "$debian_output"
        sed -i '/snuffleupagus/d' "$debian_output"
    fi
done

# Step 3: Build multi-PHP Dockerfile
log_info "  Building multi-PHP variant..."
multi_output="Dockerfile-multi"
cat "$TEMPLATE_HEADER" > "$multi_output"
for version in "${VERSIONS[@]}"; do
    temp="Dockerfile-template.generated.php${version}"
    cat "$temp" >> "$multi_output"
done
cat "$TEMPLATE_FOOTER" >> "$multi_output"

safe_sed "#PHPVERSION#" "MULTI" "$multi_output"
safe_sed "MODE=FPM" "MODE=MULTI" "$multi_output"
safe_sed "rm -rf /etc/php" "#rm -rf /etc/php" "$multi_output"

# Create debian variant
multi_debian="Dockerfile-multidebian"
cp "$multi_output" "$multi_debian"
safe_sed "eilandert/ubuntu-base:rolling" "eilandert/debian-base:stable" "$multi_debian"

# Step 4: Clean up temp files
rm -f Dockerfile-template.generated.*

log_info "✓ PHP-FPM Dockerfiles generated (${#VERSIONS[@]} versions + multi)"
