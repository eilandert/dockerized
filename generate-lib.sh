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
