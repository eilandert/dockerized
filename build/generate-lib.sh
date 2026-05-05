#!/bin/bash
# Shared utilities for Dockerfile generation
# Source this file in component .generate.sh scripts

set -e

# Safe sed that works with paths containing /
# Usage: safe_sed pattern replacement file
safe_sed() {
    local pattern="$1"
    local replacement="$2"
    local file="$3"
    sed -i "s|${pattern}|${replacement}|g" "$file"
}

# Process template with substitutions
# Usage: process_template template_file output_file key1=val1 key2=val2 ...
process_template() {
    local template="$1"
    local output="$2"
    shift 2

    cp "$template" "$output"

    while [[ $# -gt 0 ]]; do
        local key="${1%%=*}"
        local val="${1#*=}"
        safe_sed "#${key}#" "$val" "$output"
        shift
    done
}

# Log functions
log_info() {
    echo "[INFO] $*"
}

log_error() {
    echo "[ERROR] $*" >&2
}

log_warn() {
    echo "[WARN] $*" >&2
}

# Check if array contains value
array_contains() {
    local needle="$1"
    shift
    local item
    for item in "$@"; do
        [[ "$item" == "$needle" ]] && return 0
    done
    return 1
}

# Validate template file exists
check_template() {
    local template="$1"
    if [[ ! -f "$template" ]]; then
        log_error "Template not found: $template"
        return 1
    fi
}

# Remove marker lines from file
remove_markers() {
    local file="$1"
    local marker="$2"
    sed -i "/${marker}/d" "$file"
}

# Compose dockerfile from header, body, and footer files
# Usage: compose_dockerfile output_file [header_file] [body_file] [footer_file]
# If body_file is an array (space-separated), concatenates all bodies
compose_dockerfile() {
    local output="$1"
    local header="${2:-}"
    local body="${3:-}"
    local footer="${4:-}"

    > "$output"  # Clear output file

    [[ -n "$header" && -f "$header" ]] && cat "$header" >> "$output"
    [[ -n "$body" && -f "$body" ]] && cat "$body" >> "$output"
    [[ -n "$footer" && -f "$footer" ]] && cat "$footer" >> "$output"
}

# Create debian variant from ubuntu file by copying and modifying base image reference
# Usage: create_debian_variant ubuntu_file debian_output
create_debian_variant() {
    local ubuntu_file="$1"
    local debian_output="$2"

    cp "$ubuntu_file" "$debian_output"
    safe_sed "eilandert/ubuntu-base:rolling" "eilandert/debian-base:stable" "$debian_output"
    safe_sed "eilandert/php-fpm:" "eilandert/php-fpm:deb-" "$debian_output"
}

# Validate all required templates exist
# Usage: validate_templates template1 template2 template3 ...
validate_templates() {
    local template
    for template in "$@"; do
        check_template "$template" || return 1
    done
    return 0
}
