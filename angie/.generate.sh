#!/bin/bash
# Generate Angie Dockerfiles from Nginx templates
# Angie is a drop-in Nginx replacement with the same Dockerfile structure
# Usage: angie/.generate.sh

set -e

SCRIPTDIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
NGINXDIR="$(cd "$SCRIPTDIR/../nginx" && pwd)"
cd "$SCRIPTDIR"
source ../generate-lib.sh

log_info "Generating Angie Dockerfiles from Nginx templates..."

# Copy bootstrap script
if [[ -f "$NGINXDIR/bootstrap.sh" ]]; then
    cp "$NGINXDIR/bootstrap.sh" "bootstrap.sh"
    safe_sed "nginx" "angie" "bootstrap.sh"
    safe_sed "NGINX" "ANGIE" "bootstrap.sh"
fi

# Copy template
if [[ -f "$NGINXDIR/Dockerfile.template" ]]; then
    cp "$NGINXDIR/Dockerfile.template" "Dockerfile.template"
    safe_sed "nginx" "angie" "Dockerfile.template"
fi

# Copy and transform all generated Dockerfiles
log_info "  Copying and transforming Nginx Dockerfiles to Angie..."
for nginx_file in "$NGINXDIR"/Dockerfile*; do
    filename=$(basename "$nginx_file")
    if [[ "$filename" == "Dockerfile.template" ]]; then
        continue  # Already copied template above
    fi
    
    cp "$nginx_file" "$filename"
    safe_sed "nginx" "angie" "$filename"
    log_info "    $filename"
done

log_info "✓ Angie Dockerfiles generated"
