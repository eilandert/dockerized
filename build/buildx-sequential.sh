#!/bin/bash
# Docker buildx SEQUENTIAL builder across 4 dependency layers
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

# Format seconds into human readable format (HH:MM:SS)
format_time() {
    local seconds=$1
    local hours=$((seconds / 3600))
    local minutes=$(((seconds % 3600) / 60))
    local secs=$((seconds % 60))
    printf "%02d:%02d:%02d" $hours $minutes $secs
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

# Persistent build cache directory - shared across all targets and runs
DEFAULT_CACHE_ROOT="${XDG_CACHE_HOME:-${HOME:-/tmp}/.cache}"
CACHE_DIR="${BUILDX_CACHE_DIR:-$DEFAULT_CACHE_ROOT/dockerized-buildx}"
mkdir -p "$CACHE_DIR"
log_info "Using build cache: $CACHE_DIR"

# Clean up any existing buildx instances
log_info "Cleaning up buildx..."
docker buildx rm 2>/dev/null || true
docker system prune -f -a 2>/dev/null || true

# Create new buildx instance
log_info "Creating buildx instance..."
docker buildx create --use 2>/dev/null || true

# Define build targets organized by dependency layer
# PHP versions built: 5.6, 7.4, 8.0, 8.2, 8.4, 8.5
declare -a LAYERS=(
    # Layer 1: Base images (6 targets) - no dependencies
    "resolute noble jammy trixie rolling devel"
    
    # Layer 2: PHP-FPM and Databases - depends on base images
    # Includes: 56, 74, 80, 82, 84, 85, multiphp, mariadb, redis, valkey
    "ubuntu-phpfpm56 debian-phpfpm56 ubuntu-phpfpm74 debian-phpfpm74 ubuntu-phpfpm80 debian-phpfpm80 ubuntu-phpfpm82 debian-phpfpm82 ubuntu-phpfpm84 debian-phpfpm84 ubuntu-phpfpm85 debian-phpfpm85 ubuntu-multiphp debian-multiphp ubuntu-mariadb debian-mariadb ubuntu-redis debian-redis ubuntu-valkey debian-valkey"

    # Layer 3: Web servers with PHP - depends on PHP-FPM
    # Includes nginx/angie/apache with: 56, 74, 80, 82, 84, 85
    "ubuntu-nginx-php56 debian-nginx-php56 ubuntu-nginx-php74 debian-nginx-php74 ubuntu-nginx-php80 debian-nginx-php80 ubuntu-nginx-php82 debian-nginx-php82 ubuntu-nginx-php84 debian-nginx-php84 ubuntu-nginx-php85 debian-nginx-php85 ubuntu-nginx-multi debian-nginx-multi ubuntu-angie-php56 debian-angie-php56 ubuntu-angie-php74 debian-angie-php74 ubuntu-angie-php80 debian-angie-php80 ubuntu-angie-php82 debian-angie-php82 ubuntu-angie-php84 debian-angie-php84 ubuntu-angie-php85 debian-angie-php85 ubuntu-angie-multi debian-angie-multi debian-apache-php56 debian-apache-php74 debian-apache-php80 debian-apache-php82 debian-apache-php84 debian-apache-php85 debian-apache-multiphp ubuntu-apache-php56 ubuntu-apache-php74 ubuntu-apache-php80 ubuntu-apache-php82 ubuntu-apache-php84 ubuntu-apache-php85 ubuntu-apache-multiphp"
    
    # Layer 4: Other web servers and services - depends on base images
    "debian-nginx ubuntu-nginx debian-angie ubuntu-angie ubuntu-postfix debian-postfix alpine-rspamd debian-rspamd-git debian-rspamd debian-rspamd-official ubuntu-rspamd ubuntu-dovecot debian-dovecot debian-roundcube debian-vimbadmin ubuntu-vimbadmin ubuntu-reprepro debian-sitewarmup alpine-letsencrypt rbldnsd alpine-unbound aptly debian-openssh"
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
BUILD_START_TIME=$(date +%s)
declare -a FAILED_TARGETS=()

# Calculate total targets
for LAYER in "${LAYERS[@]}"; do
    for target in $LAYER; do
        TOTAL_TARGETS=$((TOTAL_TARGETS+1))
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
        layer_size=$((layer_size+1))
    done
    
    echo "========================================="
    log_info "Layer $LAYER_NUM ($layer_size targets)"
    echo "========================================="
    echo ""
    
    TARGET_IN_LAYER=0
    for TARGET in $LAYER; do
        TARGET_IN_LAYER=$((TARGET_IN_LAYER+1))
        CURRENT_TARGET_NUM=$((CURRENT_TARGET_NUM+1))
        TARGET_START_TIME=$(date +%s)
        
        # Progress display
        pct=$((CURRENT_TARGET_NUM * 100 / TOTAL_TARGETS))
        log_build "[$CURRENT_TARGET_NUM/$TOTAL_TARGETS ($pct%)] Layer $LAYER_NUM, Target $TARGET_IN_LAYER/$layer_size: $TARGET"
        
        # Individual log per target
        TARGET_LOG="/tmp/buildx-target-$TARGET.log"
        rm -f "$TARGET_LOG"
        
        # Build single target (30 minute timeout per target)
        if timeout 1800 docker buildx bake -f "$PROJECT_ROOT/docker-bake.hcl" \
        --set "*.cache-from=type=local,src=$CACHE_DIR" \
        --set "*.cache-to=type=local,dest=$CACHE_DIR,mode=max" \
        --progress=plain \
        ${PUSH} $TARGET > "$TARGET_LOG" 2>&1; then
            
            SUCCESS=$((SUCCESS+1))
            TARGET_ELAPSED=$(($(date +%s) - TARGET_START_TIME))
            log_info "  ✓ SUCCESS ($(format_time $TARGET_ELAPSED))"
            
        else
            EXIT_CODE=$?
            TARGET_ELAPSED=$(($(date +%s) - TARGET_START_TIME))
            if [ $EXIT_CODE -eq 124 ]; then
                log_error "  ✗ TIMEOUT (exceeded 30 minutes / $(format_time $TARGET_ELAPSED))"
            else
                log_error "  ✗ FAILED ($(format_time $TARGET_ELAPSED) exit code: $EXIT_CODE)"
            fi
            
            # Show full log path and error excerpt
            log_error "  Full log: /tmp/buildx-target-$TARGET.log"
            if grep -q "ERROR\|error:" "$TARGET_LOG" 2>/dev/null; then
                log_error "  Error summary:"
                grep -E "(ERROR|error:|FAILED)" "$TARGET_LOG" 2>/dev/null | head -2 | sed 's/^/    /'
            fi
            
            FAILED=$((FAILED+1))
            FAILED_TARGETS+=("$TARGET")
        fi
        echo ""
    done
    
    log_info "Layer $LAYER_NUM: $SUCCESS/$CURRENT_TARGET_NUM targets completed"
    echo ""
    LAYER_NUM=$((LAYER_NUM+1))
done

# Cleanup
log_info "Cleaning up buildx..."
docker buildx rm 2>/dev/null || true
docker system prune -f -a 2>/dev/null || true

# Final Summary
echo ""
echo "========================================="
log_info "BUILD COMPLETE"
# Summary - save to file and print
SUMMARY_FILE="/tmp/buildx-summary-$(date +%s).txt"
{
    echo "========================================="
    echo "Build Summary"
    echo "========================================="
    echo "Successful: $SUCCESS/$TOTAL_TARGETS"
    echo "Failed: $FAILED/$TOTAL_TARGETS"
    BUILD_ELAPSED=$(($(date +%s) - BUILD_START_TIME))
    echo "Total Time: $(format_time $BUILD_ELAPSED)"
    echo ""
    
    if [ $SUCCESS -eq $TOTAL_TARGETS ]; then
        echo "✓ All targets built successfully!"
    else
        echo ""
        echo "========================================="
        echo "FAILED TARGETS SUMMARY ($FAILED failures)"
        echo "========================================="
        for i in "${!FAILED_TARGETS[@]}"; do
            target="${FAILED_TARGETS[$i]}"
            echo ""
            echo "[$((i+1))/$FAILED] $target"
            
            # Show error details from log
            TARGET_LOG="/tmp/buildx-target-$target.log"
            if [ -f "$TARGET_LOG" ]; then
                if grep -q "TIMEOUT\|timeout" "$TARGET_LOG" 2>/dev/null; then
                    echo "  └─ Reason: Build timeout (exceeded 30 minutes)"
                    elif grep -q "permission denied" "$TARGET_LOG" 2>/dev/null; then
                    echo "  └─ Reason: Permission denied (Docker daemon access)"
                    elif grep -q "ERROR\|error:" "$TARGET_LOG" 2>/dev/null; then
                    echo "  └─ Error details:"
                    grep -E "(ERROR|error:|FAILED)" "$TARGET_LOG" 2>/dev/null | head -2 | sed 's/^/     /'
                else
                    echo "  └─ See full log: $TARGET_LOG"
                fi
            fi
        done
        echo ""
        echo "========================================="
        echo "To investigate failures, run:"
        echo "  tail -100 /tmp/buildx-target-<target-name>.log"
        echo "========================================="
    fi
} | tee "$SUMMARY_FILE"

echo ""
BUILD_ELAPSED=$(($(date +%s) - BUILD_START_TIME))
echo "========================================="
echo -e "  ${GREEN}Successful${NC}: $SUCCESS/$TOTAL_TARGETS"
echo -e "  ${RED}Failed${NC}: $FAILED/$TOTAL_TARGETS"
echo -e "  ${BLUE}Total Time${NC}: $(format_time $BUILD_ELAPSED)"
echo ""

if [ $SUCCESS -eq $TOTAL_TARGETS ]; then
    log_info "✓ All targets built successfully!"
else
    echo ""
    echo "========================================="
    log_warning "FAILED TARGETS SUMMARY ($FAILED failures)"
    echo "========================================="
    for i in "${!FAILED_TARGETS[@]}"; do
        target="${FAILED_TARGETS[$i]}"
        echo ""
        echo -e "${RED}[$((i+1))/$FAILED]${NC} $target"
        
        # Show error details from log
        TARGET_LOG="/tmp/buildx-target-$target.log"
        if [ -f "$TARGET_LOG" ]; then
            if grep -q "TIMEOUT\|timeout" "$TARGET_LOG" 2>/dev/null; then
                echo "  └─ Reason: Build timeout (exceeded 30 minutes)"
                elif grep -q "permission denied" "$TARGET_LOG" 2>/dev/null; then
                echo "  └─ Reason: Permission denied (Docker daemon access)"
                elif grep -q "ERROR\|error:" "$TARGET_LOG" 2>/dev/null; then
                echo "  └─ Error details:"
                grep -E "(ERROR|error:|FAILED)" "$TARGET_LOG" 2>/dev/null | head -2 | sed 's/^/     /'
            else
                echo "  └─ See full log: $TARGET_LOG"
            fi
        fi
    done
    echo ""
    echo "========================================="
    echo -e "To investigate failures, run:"
    echo "  tail -100 /tmp/buildx-target-<target-name>.log"
    echo "========================================="
    echo ""
fi

echo ""
log_info "Summary saved to: $SUMMARY_FILE"
echo ""

if [ $FAILED -gt 0 ]; then
    exit 1
fi
