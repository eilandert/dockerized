#!/bin/bash
set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1" >&2
}

log_warning() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

# Ensure the push is only initiated on build machine
PUSH=""
if [ "$(uname -n)" == "build" ]; then
    PUSH="--push"
    log_info "Push enabled for build machine"
else
    log_warning "Running on $(uname -n), push disabled"
fi

# Remote aptly sync
log_info "Syncing with remote aptly server..."
ssh -p 8889 aptly@192.168.178.11 /aptly/scripts/daily.sh || log_warning "Remote sync failed, continuing anyway"

# Track last run
date > /tmp/dockerized.lastrun

# Generate dockerfiles and prepare other things
log_info "Generating Dockerfiles..."
if ! ./generate.sh; then
    log_error "generate.sh failed"
    exit 1
fi

# Clean up any existing buildx instances
log_info "Cleaning up buildx..."
docker buildx rm 2>/dev/null || true
docker system prune -f -a

# Create new buildx instance
log_info "Creating buildx instance..."
docker buildx create --use

# Define build targets (extracted from docker-bake.hcl groups for clarity)
# These are sorted for consistency
declare -a TARGETS=(
    "alpine-letsencrypt"
    "alpine-rspamd"
    "alpine-unbound"
    "aptly"
    "bullseye-apache-fpm81"
    "bullseye-phpfpm81"
    "clamav"
    "debian-angie"
    "debian-angie-multi"
    "debian-angie-php56"
    "debian-angie-php72"
    "debian-angie-php74"
    "debian-angie-php80"
    "debian-angie-php81"
    "debian-angie-php82"
    "debian-angie-php83"
    "debian-angie-php84"
    "debian-apache-multiphp"
    "debian-apache-php56"
    "debian-apache-php72"
    "debian-apache-php74"
    "debian-apache-php80"
    "debian-apache-php81"
    "debian-apache-php82"
    "debian-apache-php83"
    "debian-apache-php84"
    "debian-dovecot"
    "debian-mariadb"
    "debian-multiphp"
    "debian-nginx"
    "debian-nginx-multi"
    "debian-nginx-php56"
    "debian-nginx-php72"
    "debian-nginx-php74"
    "debian-nginx-php80"
    "debian-nginx-php81"
    "debian-nginx-php82"
    "debian-nginx-php83"
    "debian-nginx-php84"
    "debian-openssh"
    "debian-phpfpm56"
    "debian-phpfpm72"
    "debian-phpfpm74"
    "debian-phpfpm80"
    "debian-phpfpm81"
    "debian-phpfpm82"
    "debian-phpfpm83"
    "debian-phpfpm84"
    "debian-postfix"
    "debian-redis"
    "debian-roundcube"
    "debian-rspamd"
    "debian-rspamd-git"
    "debian-rspamd-official"
    "debian-sitewarmup"
    "debian-valkey"
    "debian-vimbadmin"
    "rbldnsd"
    "resolute"
    "rolling"
    "trixie"
    "ubuntu-angie"
    "ubuntu-angie-php56"
    "ubuntu-angie-php72"
    "ubuntu-angie-php74"
    "ubuntu-angie-php80"
    "ubuntu-angie-php81"
    "ubuntu-angie-php82"
    "ubuntu-angie-php83"
    "ubuntu-angie-php84"
    "ubuntu-apache-multiphp"
    "ubuntu-apache-php56"
    "ubuntu-apache-php72"
    "ubuntu-apache-php74"
    "ubuntu-apache-php80"
    "ubuntu-apache-php81"
    "ubuntu-apache-php82"
    "ubuntu-apache-php83"
    "ubuntu-apache-php84"
    "ubuntu-dovecot"
    "ubuntu-mariadb"
    "ubuntu-multiphp"
    "ubuntu-nginx"
    "ubuntu-nginx-multi"
    "ubuntu-nginx-php56"
    "ubuntu-nginx-php72"
    "ubuntu-nginx-php74"
    "ubuntu-nginx-php80"
    "ubuntu-nginx-php81"
    "ubuntu-nginx-php82"
    "ubuntu-nginx-php83"
    "ubuntu-nginx-php84"
    "ubuntu-phpfpm56"
    "ubuntu-phpfpm72"
    "ubuntu-phpfpm74"
    "ubuntu-phpfpm80"
    "ubuntu-phpfpm81"
    "ubuntu-phpfpm82"
    "ubuntu-phpfpm83"
    "ubuntu-phpfpm84"
    "ubuntu-postfix"
    "ubuntu-redis"
    "ubuntu-reprepro"
    "ubuntu-rspamd"
    "ubuntu-valkey"
    "ubuntu-vimbadmin"
)

# Build targets
log_info "Starting builds for ${#TARGETS[@]} targets..."
FAILED=0
SUCCESS=0

for BUILD in "${TARGETS[@]}"; do
    echo ""
    log_info "Building: ${BUILD}"
    if docker buildx bake ${PUSH} "${BUILD}" 2>&1 | tail -5; then
        ((SUCCESS++))
    else
        log_error "Build failed for ${BUILD}"
        ((FAILED++))
    fi
done

# Cleanup
log_info "Cleaning up..."
docker buildx rm 2>/dev/null || true
docker system prune -f -a

# Summary
echo ""
log_info "Build complete!"
echo "  Successful: $SUCCESS"
echo "  Failed: $FAILED"

if [ $FAILED -gt 0 ]; then
    exit 1
fi
