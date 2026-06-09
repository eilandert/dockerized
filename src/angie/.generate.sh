#!/bin/bash
# Generate Angie Dockerfiles from Nginx templates
# Angie is a drop-in Nginx replacement with the same Dockerfile structure
# Usage: angie/.generate.sh

set -e

SCRIPTDIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
NGINXDIR="$(cd "$SCRIPTDIR/../nginx" && pwd)"
cd "$SCRIPTDIR"
source ../../build/generate-lib.sh

log_info "Generating Angie Dockerfiles from Nginx templates..."

# Copy bootstrap script
if [[ -f "$NGINXDIR/bootstrap.sh" ]]; then
    cp "$NGINXDIR/bootstrap.sh" "bootstrap.sh"
    safe_sed "nginx" "angie" "bootstrap.sh"
    safe_sed "Nginx" "Angie" "bootstrap.sh"
    safe_sed "NGINX" "ANGIE" "bootstrap.sh"
fi

# Copy template
if [[ -f "$NGINXDIR/Dockerfile.template" ]]; then
    cp "$NGINXDIR/Dockerfile.template" "Dockerfile.template"
    safe_sed "nginx" "angie" "Dockerfile.template"
    safe_sed "Nginx" "Angie" "Dockerfile.template"
fi

# Copy hardening snippets (referenced by COPY in the template). They are
# distro-neutral so we copy them verbatim — no sed needed.
for asset in 01-hardening.conf 02-rate-limits.conf \
             security-headers.conf ssl-hardening.conf \
             deny-hidden-files.conf; do
    if [[ -f "$NGINXDIR/$asset" ]]; then
        cp "$NGINXDIR/$asset" "$asset"
    fi
done

# healthcheck.sh + healthz.conf: copy from nginx (source of truth) and apply the
# nginx->angie seds. Previously these were hand-maintained in src/angie/ and
# drifted from src/nginx/ — generating them here keeps them in lockstep.
for asset in healthcheck.sh healthz.conf; do
    if [[ -f "$NGINXDIR/$asset" ]]; then
        cp "$NGINXDIR/$asset" "$asset"
        safe_sed "nginx" "angie" "$asset"
        safe_sed "Nginx" "Angie" "$asset"
        safe_sed "NGINX" "ANGIE" "$asset"
    fi
done

# s6-overlay service tree + init-bootstrap script. Copy verbatim, then apply the
# nginx->angie seds (binary name /usr/sbin/nginx -> /usr/sbin/angie, /run/nginx
# -> /run/angie, /etc/nginx -> /etc/angie, log tags, etc). The s6-rc.d directory
# name `nginx` (the web-server longrun) is renamed to `angie` too, and its
# dependency reference inside other services updated.
rm -rf s6-rc.d s6-scripts
cp -r "$NGINXDIR/s6-rc.d" s6-rc.d
cp -r "$NGINXDIR/s6-scripts" s6-scripts
# Rename the web-server service dir nginx -> angie and its dependency stubs.
if [[ -d s6-rc.d/nginx ]]; then
    mv s6-rc.d/nginx s6-rc.d/angie
fi
mv s6-rc.d/user/contents.d/nginx s6-rc.d/user/contents.d/angie 2>/dev/null || true
# ticket-reload depends on the web-server service: rename the dependency stub.
mv s6-rc.d/ticket-reload/dependencies.d/nginx s6-rc.d/ticket-reload/dependencies.d/angie 2>/dev/null || true
# Apply text seds to every run/script file (binary paths, /run, /etc, tags).
while IFS= read -r f; do
    safe_sed "nginx" "angie" "$f"
    safe_sed "Nginx" "Angie" "$f"
    safe_sed "NGINX" "ANGIE" "$f"
done < <(find s6-rc.d s6-scripts -type f \( -name run -o -name up -o -name '*.sh' \))

# Copy and transform all generated Dockerfiles
log_info "  Copying and transforming Nginx Dockerfiles to Angie..."
for nginx_file in "$NGINXDIR"/Dockerfile*; do
    filename=$(basename "$nginx_file")
    if [[ "$filename" == "Dockerfile.template" ]]; then
        continue  # Already copied template above
    fi
    
    cp "$nginx_file" "$filename"
    safe_sed "nginx" "angie" "$filename"
    safe_sed "Nginx" "Angie" "$filename"
    log_info "    $filename"
done

log_info "✓ Angie Dockerfiles generated"
