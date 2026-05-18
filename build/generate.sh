#!/bin/bash
# Main Dockerfile generation orchestrator
# This script coordinates generation of all Dockerfiles from templates
# Each component has its own .generate.sh script in its directory

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log_info() {
    echo -e "${GREEN}[INFO]${NC} $*"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $*" >&2
}

log_section() {
    echo ""
    echo "===== $* ====="
}

SCRIPTDIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPTDIR"

# Ensure generate-lib.sh exists
if [[ ! -f generate-lib.sh ]]; then
    log_error "generate-lib.sh not found"
    exit 1
fi

log_section "Dockerfile Generation"

# Define components in dependency order
declare -a COMPONENTS=(
    "base"              # Layer 1: Base images
    "php-fpm"           # Layer 2: PHP-FPM (depends on base)
    "apache-phpfpm"     # Layer 2: Apache PHP-FPM (depends on base)
    "nginx"             # Layer 3: Nginx (depends on php-fpm)
    "angie"             # Layer 3: Angie (depends on nginx)
)

FAILED=0
FAILED_COMPONENTS=()

# Run each component's generation
for component in "${COMPONENTS[@]}"; do
    gen_script="../src/$component/.generate.sh"

    if [[ ! -f "$gen_script" ]]; then
        log_error "Generate script not found: $gen_script"
        ((FAILED++))
        FAILED_COMPONENTS+=("$component")
        continue
    fi

    log_info "Processing: $component"
    if bash "$gen_script"; then
        log_info "  ✓ $component"
    else
        log_error "  ✗ $component failed"
        ((FAILED++))
        FAILED_COMPONENTS+=("$component")
    fi
done

# Handle special/static components that don't regenerate (upstream sources)
log_section "Handling External/Static Components"

log_info "Syncing MariaDB Dockerfiles from upstream..."
if bash -c '
    set -e
    curl --fail -s https://raw.githubusercontent.com/MariaDB/mariadb-docker/master/10.11/Dockerfile -o ../src/mariadb/Dockerfile-ubu
    curl --fail -s https://raw.githubusercontent.com/MariaDB/mariadb-docker/master/10.11/docker-entrypoint.sh -o ../src/mariadb/docker-entrypoint.sh
    curl --fail -s https://raw.githubusercontent.com/MariaDB/mariadb-docker/master/10.11/healthcheck.sh -o ../src/mariadb/healthcheck.sh

    # Create debian variant for the filenames consumed by docker bake/buildx
    cp ../src/mariadb/Dockerfile-ubu ../src/mariadb/Dockerfile-deb
    chmod +x ../src/mariadb/docker-entrypoint.sh

    # Customize for our setup
    sed -i "s|FROM ubuntu:jammy|FROM eilandert/ubuntu-base:rolling\nCOPY bootstrap.sh /|" ../src/mariadb/Dockerfile-ubu
    sed -i "s|FROM ubuntu:jammy|FROM eilandert/debian-base:stable\nCOPY bootstrap.sh /|" ../src/mariadb/Dockerfile-deb
    sed -i "s|jammy|noble|g" ../src/mariadb/Dockerfile-ubu
    sed -i "s|jammy|trixie|g" ../src/mariadb/Dockerfile-deb
    sed -i "s|repo/ubuntu|repo/debian|g" ../src/mariadb/Dockerfile-deb
    sed -i "s|org.opencontainers.image.version=\"10.11.16\"|org.opencontainers.image.version=\"11.8\"|" ../src/mariadb/Dockerfile-ubu
    sed -i "s|org.opencontainers.image.version=\"10.11.16\"|org.opencontainers.image.version=\"11.8\"|" ../src/mariadb/Dockerfile-deb
    sed -i "s|org.opencontainers.image.base.name=\"docker.io/library/ubuntu:noble\"|org.opencontainers.image.base.name=\"docker.io/eilandert/ubuntu-base:rolling\"|" ../src/mariadb/Dockerfile-ubu
    sed -i "s|org.opencontainers.image.base.name=\"docker.io/library/ubuntu:trixie\"|org.opencontainers.image.base.name=\"docker.io/eilandert/debian-base:stable\"|" ../src/mariadb/Dockerfile-deb
    sed -i '/^ARG MARIADB_VERSION=/d' ../src/mariadb/Dockerfile-ubu
    sed -i '/^ENV MARIADB_VERSION /d' ../src/mariadb/Dockerfile-ubu
    sed -i '/^ARG MARIADB_VERSION=/d' ../src/mariadb/Dockerfile-deb
    sed -i '/^ENV MARIADB_VERSION /d' ../src/mariadb/Dockerfile-deb
    sed -i 's|ARG REPOSITORY=.*|ARG REPOSITORY="https://dlm.mariadb.com/repo/mariadb-server/11.8/repo/ubuntu/ noble main"|' ../src/mariadb/Dockerfile-ubu
    sed -i 's|ARG REPOSITORY=.*|ARG REPOSITORY="https://dlm.mariadb.com/repo/mariadb-server/11.8/repo/debian/ trixie main"|' ../src/mariadb/Dockerfile-deb
    sed -i 's|apt-get install -y --no-install-recommends mariadb-server="\\$MARIADB_VERSION" mariadb-backup socat|apt-get install -y --no-install-recommends mariadb-server mariadb-backup socat|' ../src/mariadb/Dockerfile-ubu
    sed -i 's|apt-get install -y --no-install-recommends mariadb-server="\\$MARIADB_VERSION" mariadb-backup socat|apt-get install -y --no-install-recommends mariadb-server mariadb-backup socat|' ../src/mariadb/Dockerfile-deb

    # Keep legacy filenames in sync for any scripts still referencing them directly.
    cp ../src/mariadb/Dockerfile-ubu ../src/mariadb/Dockerfile.ubuntu
    cp ../src/mariadb/Dockerfile-deb ../src/mariadb/Dockerfile.debian
'; then
    log_info "  ✓ MariaDB"
else
    log_error "  ✗ MariaDB sync failed"
    ((FAILED++))
    FAILED_COMPONENTS+=("mariadb-upstream")
fi

# Get roundcube version if available
if command -v lastversion &> /dev/null; then
    log_info "Checking Roundcube version..."
    if LASTVERSION=$(lastversion -b 1.6 https://github.com/roundcube/roundcubemail/ 2>/dev/null); then
        if [[ -n "$LASTVERSION" ]]; then
            echo "$LASTVERSION" > ../src/roundcube/.lastversion
            log_info "  Roundcube version: $LASTVERSION"
        fi
    fi
else
    log_info "  lastversion not installed, skipping version check"
fi

# Git commit all changes
log_section "Committing Changes"

if [[ $(git status --porcelain | wc -l) -gt 0 ]]; then
    log_info "Staging generated files..."
    git add -A ../src/base/ ../src/php-fpm/ ../src/apache-phpfpm/ ../src/nginx/ ../src/angie/ ../src/mariadb/ ../src/roundcube/.lastversion ../docker-bake.hcl 2>/dev/null || true

    log_info "Committing..."
    git commit -m "autogenerated: dockerfile generation from templates" || log_error "Git commit failed"

    log_info "Pushing..."
    git push || log_error "Git push failed (may need credentials)"
else
    log_info "No changes to commit"
fi

# Summary
log_section "Generation Complete"
if [[ $FAILED -eq 0 ]]; then
    echo -e "${GREEN}✓ All components generated successfully${NC}"
    exit 0
else
    echo -e "${RED}✗ Failed components: ${FAILED_COMPONENTS[*]}${NC}"
    exit 1
fi


