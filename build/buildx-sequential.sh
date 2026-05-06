#!/bin/bash
# Docker buildx SEQUENTIAL builder for 122 targets across 4 dependency layers
# Builds one target at a time (NOT parallel) to maintain order and simplicity

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
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

log_build() {
    echo -e "${CYAN}[BUILD]${NC} $1"
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

# Change to parent directory for docker buildx
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
BUILD_DIR="$SCRIPT_DIR"
cd "$PROJECT_ROOT"

# Clean up any existing buildx instances
log_info "Cleaning up buildx..."
docker buildx rm 2>/dev/null || true
docker system prune -f -a

# Create new buildx instance
log_info "Creating buildx instance..."
docker buildx create --use

# Define build targets organized by dependency layer
# NOTE: php8.4 and php8.5 included in all applicable layers
declare -a LAYERS=(
    # Layer 1: Base images (14 targets) - no dependencies
    "resolute noble jammy focal bionic xenial trusty trixie bookworm bullseye buster stretch rolling devel"

    # Layer 2: PHP-FPM and Databases (26 targets) - depends on base images
    # Includes: 56, 72, 74, 80, 81, 82, 83, 84 (NEW), 85 (NEW), multiphp, mariadb, redis, valkey
    "ubuntu-phpfpm56 debian-phpfpm56 ubuntu-phpfpm72 debian-phpfpm72 ubuntu-phpfpm74 debian-phpfpm74 ubuntu-phpfpm80 debian-phpfpm80 ubuntu-phpfpm81 debian-phpfpm81 ubuntu-phpfpm82 debian-phpfpm82 ubuntu-phpfpm83 debian-phpfpm83 ubuntu-phpfpm84 debian-phpfpm84 ubuntu-phpfpm85 debian-phpfpm85 ubuntu-multiphp debian-multiphp ubuntu-mariadb debian-mariadb ubuntu-redis debian-redis ubuntu-valkey debian-valkey"

    # Layer 3: Web servers with PHP (62+ targets) - depends on PHP-FPM
    # Includes nginx/angie/apache with: 56, 72, 74, 80, 81, 82, 83, 84 (NEW), 85 (NEW)
    "ubuntu-nginx-php56 debian-nginx-php56 ubuntu-nginx-php72 debian-nginx-php72 ubuntu-nginx-php74 debian-nginx-php74 ubuntu-nginx-php80 debian-nginx-php80 ubuntu-nginx-php81 debian-nginx-php81 ubuntu-nginx-php82 debian-nginx-php82 ubuntu-nginx-php83 debian-nginx-php83 ubuntu-nginx-php84 debian-nginx-php84 ubuntu-nginx-php85 debian-nginx-php85 ubuntu-nginx-multi debian-nginx-multi ubuntu-angie-php56 debian-angie-php56 ubuntu-angie-php72 debian-angie-php72 ubuntu-angie-php74 debian-angie-php74 ubuntu-angie-php80 debian-angie-php80 ubuntu-angie-php81 debian-angie-php81 ubuntu-angie-php82 debian-angie-php82 ubuntu-angie-php83 debian-angie-php83 ubuntu-angie-php84 debian-angie-php84 ubuntu-angie-php85 debian-angie-php85 ubuntu-angie-multi debian-angie-multi debian-apache-php56 debian-apache-php72 debian-apache-php74 debian-apache-php80 debian-apache-php81 debian-apache-php82 debian-apache-php83 debian-apache-php84 debian-apache-php85 debian-apache-multiphp ubuntu-apache-php56 ubuntu-apache-php72 ubuntu-apache-php74 ubuntu-apache-php80 ubuntu-apache-php81 ubuntu-apache-php82 ubuntu-apache-php83 ubuntu-apache-php84 ubuntu-apache-php85 ubuntu-apache-multiphp"

    # Layer 4: Other web servers and services (20 targets) - depends on base images
    "debian-nginx ubuntu-nginx debian-angie ubuntu-angie ubuntu-postfix debian-postfix alpine-rspamd debian-rspamd-git debian-rspamd debian-rspamd-official ubuntu-rspamd ubuntu-dovecot debian-dovecot debian-roundcube debian-vimbadmin ubuntu-vimbadmin ubuntu-reprepro clamav alpine-letsencrypt rbldnsd alpine-unbound debian-openssh"
)

echo ""
log_info "========================================="
log_info "SEQUENTIAL BUILD MODE (One target at a time)"
log_info "========================================="
echo ""

FAILED=0
SUCCESS=0
TOTAL_TARGETS=0
CURRENT_TARGET_NUM=0
declare -a FAILED_TARGETS=()

# Calculate total targets
for LAYER in "${LAYERS[@]}"; do
    for target in $LAYER; do
        ((TOTAL_TARGETS++))
    done
done

log_info "Total targets to build: $TOTAL_TARGETS"
log_info "Estimated time: ~90-120 minutes (30s-1m per target)"
echo ""

echo "========================================="
log_info "MONITORING:"
echo "========================================="
log_info "Watch progress in another terminal:"
log_info "  tail -f /tmp/buildx-target-*.log"
log_info "Or count completed targets:"
log_info "  ls /tmp/buildx-target-*.log | wc -l"
echo ""

LAYER_NUM=1
for LAYER in "${LAYERS[@]}"; do
    layer_size=0
    for target in $LAYER; do
        ((layer_size++))
    done

    echo "========================================="
    log_info "Layer $LAYER_NUM ($layer_size targets)"
    echo "========================================="
    echo ""

    TARGET_IN_LAYER=0
    for TARGET in $LAYER; do
        ((TARGET_IN_LAYER++))
        ((CURRENT_TARGET_NUM++))

        # Progress display
        pct=$((CURRENT_TARGET_NUM * 100 / TOTAL_TARGETS))
        log_build "[$CURRENT_TARGET_NUM/$TOTAL_TARGETS ($pct%)] Layer $LAYER_NUM, Target $TARGET_IN_LAYER/$layer_size: $TARGET"

        # Individual log per target
        TARGET_LOG="/tmp/buildx-target-$TARGET.log"
        rm -f "$TARGET_LOG"

        # Build single target (30 minute timeout per target)
        if timeout 1800 docker buildx bake -f "$BUILD_DIR/docker-bake.hcl" \
            --progress=plain \
            ${PUSH} $TARGET > "$TARGET_LOG" 2>&1; then

            ((SUCCESS++))
            log_info "  ✓ SUCCESS"

        else
            EXIT_CODE=$?
            if [ $EXIT_CODE -eq 124 ]; then
                log_error "  ✗ TIMEOUT (exceeded 30 minutes)"
            else
                log_error "  ✗ FAILED (exit code: $EXIT_CODE)"
            fi

            # Show full log path and error excerpt
            log_error "  Full log: /tmp/buildx-target-$TARGET.log"
            if grep -q "ERROR\|error:" "$TARGET_LOG" 2>/dev/null; then
                log_error "  Error summary:"
                grep -E "(ERROR|error:|FAILED)" "$TARGET_LOG" 2>/dev/null | head -2 | sed 's/^/    /'
            fi

            ((FAILED++))
            FAILED_TARGETS+=("$TARGET")
        fi
        echo ""
    done

    log_info "Layer $LAYER_NUM: $SUCCESS/$CURRENT_TARGET_NUM targets completed"
    echo ""
    ((LAYER_NUM++))
done

# Cleanup
log_info "Cleaning up buildx..."
docker buildx rm 2>/dev/null || true
docker system prune -f -a

# Final Summary
echo ""
echo "========================================="
log_info "BUILD COMPLETE"
echo "========================================="
echo -e "  ${GREEN}Successful${NC}: $SUCCESS/$TOTAL_TARGETS"
echo -e "  ${RED}Failed${NC}: $FAILED/$TOTAL_TARGETS"
echo ""

if [ $SUCCESS -eq $TOTAL_TARGETS ]; then
    log_info "✓ All targets built successfully!"
else
    log_warning "⚠ Failed targets ($FAILED):"
    for target in "${FAILED_TARGETS[@]}"; do
        echo "  - $target"
        echo "    Full log: /tmp/buildx-target-$target.log"
    done
    echo ""
fi

echo ""

if [ $FAILED -gt 0 ]; then
    exit 1
fi
