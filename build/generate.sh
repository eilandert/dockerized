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
        FAILED=$((FAILED+1))
        FAILED_COMPONENTS+=("$component")
        continue
    fi

    log_info "Processing: $component"
    if bash "$gen_script"; then
        log_info "  ✓ $component"
    else
        log_error "  ✗ $component failed"
        FAILED=$((FAILED+1))
        FAILED_COMPONENTS+=("$component")
    fi
done

# Handle special/static components that don't regenerate (upstream sources)
log_section "Handling External/Static Components"

# MariaDB Dockerfiles are pulled from upstream and patched with a chain of
# sed substitutions. Each substitution is asserted afterwards so an upstream
# rename fails loudly instead of producing a silently-wrong Dockerfile.
#
# Override the upstream pin via env: MARIADB_UPSTREAM_REF (tag or branch),
# MARIADB_UPSTREAM_PATH (e.g. "10.11", "11.4").
MARIADB_UPSTREAM_REF="${MARIADB_UPSTREAM_REF:-master}"
MARIADB_UPSTREAM_PATH="${MARIADB_UPSTREAM_PATH:-10.11}"
MARIADB_TARGET_VERSION="${MARIADB_TARGET_VERSION:-11.8}"

log_info "Syncing MariaDB Dockerfiles from upstream (ref=${MARIADB_UPSTREAM_REF}, path=${MARIADB_UPSTREAM_PATH}, target=${MARIADB_TARGET_VERSION})..."

# assert_subst <file> <expected-string-after-edit> <description>
# Used to verify each sed change actually landed. If upstream renames a
# label or moves a FROM line, this will fail the run instead of producing
# a Dockerfile that quietly references the wrong base / wrong repo.
assert_subst() {
    local file="$1" needle="$2" desc="$3"
    if ! grep -qF "$needle" "$file"; then
        log_error "    MariaDB patch assertion failed in $(basename "$file"): $desc"
        log_error "    expected to find: $needle"
        return 1
    fi
}

if (
    set -e
    BASE_URL="https://raw.githubusercontent.com/MariaDB/mariadb-docker/${MARIADB_UPSTREAM_REF}/${MARIADB_UPSTREAM_PATH}"
    curl --fail -sSL "${BASE_URL}/Dockerfile"          -o ../src/mariadb/Dockerfile-ubu
    curl --fail -sSL "${BASE_URL}/docker-entrypoint.sh" -o ../src/mariadb/docker-entrypoint.sh
    curl --fail -sSL "${BASE_URL}/healthcheck.sh"       -o ../src/mariadb/healthcheck.sh

    cp ../src/mariadb/Dockerfile-ubu ../src/mariadb/Dockerfile-deb
    chmod +x ../src/mariadb/docker-entrypoint.sh

    UBU=../src/mariadb/Dockerfile-ubu
    DEB=../src/mariadb/Dockerfile-deb

    # Rewrite FROM (upstream still uses ubuntu:jammy as of this writing)
    sed -i "s|FROM ubuntu:jammy|FROM eilandert/ubuntu-base:rolling\nCOPY bootstrap.sh /|" "$UBU"
    sed -i "s|FROM ubuntu:jammy|FROM eilandert/debian-base:stable\nCOPY bootstrap.sh /|"  "$DEB"
    assert_subst "$UBU" "FROM eilandert/ubuntu-base:rolling" "FROM rewrite (ubuntu)"
    assert_subst "$DEB" "FROM eilandert/debian-base:stable"  "FROM rewrite (debian)"

    sed -i "s|jammy|${UBUNTULTS}|g"   "$UBU"
    sed -i "s|jammy|${DEBIANSTABLE}|g" "$DEB"
    sed -i "s|repo/ubuntu|repo/debian|g" "$DEB"

    # Version label rewrite — upstream value depends on the path we fetched
    sed -i "s|org.opencontainers.image.version=\"[0-9.]*\"|org.opencontainers.image.version=\"${MARIADB_TARGET_VERSION}\"|" "$UBU"
    sed -i "s|org.opencontainers.image.version=\"[0-9.]*\"|org.opencontainers.image.version=\"${MARIADB_TARGET_VERSION}\"|" "$DEB"
    assert_subst "$UBU" "org.opencontainers.image.version=\"${MARIADB_TARGET_VERSION}\"" "version label (ubuntu)"
    assert_subst "$DEB" "org.opencontainers.image.version=\"${MARIADB_TARGET_VERSION}\"" "version label (debian)"

    sed -i "s|org.opencontainers.image.base.name=\"docker.io/library/ubuntu:${UBUNTULTS}\"|org.opencontainers.image.base.name=\"docker.io/eilandert/ubuntu-base:rolling\"|" "$UBU"
    sed -i "s|org.opencontainers.image.base.name=\"docker.io/library/ubuntu:${DEBIANSTABLE}\"|org.opencontainers.image.base.name=\"docker.io/eilandert/debian-base:stable\"|" "$DEB"

    sed -i '/^ARG MARIADB_VERSION=/d' "$UBU"
    sed -i '/^ENV MARIADB_VERSION /d'  "$UBU"
    sed -i '/^ARG MARIADB_VERSION=/d' "$DEB"
    sed -i '/^ENV MARIADB_VERSION /d'  "$DEB"

    sed -i "s|ARG REPOSITORY=.*|ARG REPOSITORY=\"https://dlm.mariadb.com/repo/mariadb-server/${MARIADB_TARGET_VERSION}/repo/ubuntu/ ${UBUNTULTS} main\"|" "$UBU"
    sed -i "s|ARG REPOSITORY=.*|ARG REPOSITORY=\"https://dlm.mariadb.com/repo/mariadb-server/${MARIADB_TARGET_VERSION}/repo/debian/ ${DEBIANSTABLE} main\"|" "$DEB"
    assert_subst "$UBU" "mariadb-server/${MARIADB_TARGET_VERSION}/repo/ubuntu/ ${UBUNTULTS} main" "REPOSITORY arg (ubuntu)"
    assert_subst "$DEB" "mariadb-server/${MARIADB_TARGET_VERSION}/repo/debian/ ${DEBIANSTABLE} main" "REPOSITORY arg (debian)"

    sed -i 's|apt-get install -y --no-install-recommends mariadb-server="\$MARIADB_VERSION" mariadb-backup socat|apt-get install -y --no-install-recommends mariadb-server mariadb-backup socat|' "$UBU"
    sed -i 's|apt-get install -y --no-install-recommends mariadb-server="\$MARIADB_VERSION" mariadb-backup socat|apt-get install -y --no-install-recommends mariadb-server mariadb-backup socat|' "$DEB"

    # Legacy filenames kept in sync for any script still referencing them.
    cp "$UBU" ../src/mariadb/Dockerfile.ubuntu
    cp "$DEB" ../src/mariadb/Dockerfile.debian
); then
    log_info "  ✓ MariaDB"
else
    log_error "  ✗ MariaDB sync failed"
    FAILED=$((FAILED+1))
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

# Git commit all changes (opt-in)
#
# Auto-commit is OFF by default — it used to fire on every developer run and
# could sweep WIP into an "autogenerated" commit. Set GENERATE_COMMIT=1 to
# enable (the build host's cron is the intended caller).
log_section "Committing Changes"

if [[ "${GENERATE_COMMIT:-0}" != "1" ]]; then
    log_info "Auto-commit disabled (set GENERATE_COMMIT=1 to enable)"
elif [[ -n "$(git status --porcelain -- \
        ../src/base/ ../src/php-fpm/ ../src/apache-phpfpm/ \
        ../src/nginx/ ../src/angie/ ../src/mariadb/ \
        ../src/roundcube/.lastversion ../docker-bake.hcl 2>/dev/null)" ]]; then
    log_info "Staging generated files..."
    git add -- \
        ../src/base/ ../src/php-fpm/ ../src/apache-phpfpm/ \
        ../src/nginx/ ../src/angie/ ../src/mariadb/ \
        ../src/roundcube/.lastversion ../docker-bake.hcl 2>/dev/null || true

    log_info "Committing..."
    if git commit -m "autogenerated: dockerfile generation from templates"; then
        log_info "Pushing..."
        if ! git push; then
            log_error "Git push failed (may need credentials)"
            FAILED=$((FAILED+1))
            FAILED_COMPONENTS+=("git-push")
        fi
    else
        log_error "Git commit failed"
        FAILED=$((FAILED+1))
        FAILED_COMPONENTS+=("git-commit")
    fi
else
    log_info "No generator changes to commit"
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


