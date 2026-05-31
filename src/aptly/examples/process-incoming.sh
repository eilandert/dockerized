#!/bin/bash

#
# Simple example script to process incoming packages, with filesystem endpoints
# 20211224 Thijs Eilander <eilander@myguard.nl>
#

: "${DELETE:=YES}"
: "${CREATE:=YES}"

set -euo pipefail
shopt -s nullglob

if [ -z "${DIST:-}" ] && [ $# -ge 1 ]; then DIST="$1"; fi
if [ -z "${REPO:-}" ] && [ $# -ge 2 ]; then REPO="$2"; fi

if [ -z "${DIST:-}" ]; then
    echo "ERROR: DIST is required" >&2
    exit 1
fi
if [ -z "${REPO:-}" ]; then
    echo "ERROR: REPO is required" >&2
    exit 1
fi
if [ -z "${DIR:-}" ]; then
    echo "ERROR: DIR is required" >&2
    exit 1
fi

if [ "${CREATE}" != "YES" ]; then unset CREATE; fi
if [ "${DELETE}" != "YES" ]; then unset DELETE; fi

if [[ ${DIR} =~ ^/tmp/ ]]; then
    WORKDIR="${DIR}"
else
    WORKDIR="/aptly/incoming/${DIR}"
fi

LOCK_SAFE_REPO=$(printf '%s' "${REPO}" | sed 's/[^A-Za-z0-9_.-]/_/g')
LOCK_SAFE_DIST=$(printf '%s' "${DIST}" | sed 's/[^A-Za-z0-9_.-]/_/g')
LOCKFILE="/tmp/process-incoming-${LOCK_SAFE_REPO}-${LOCK_SAFE_DIST}.lock"
exec 9>"${LOCKFILE}"
if ! flock -w 300 9; then
    echo "ERROR: could not acquire lock ${LOCKFILE} within 300s" >&2
    exit 1
fi

TMP_FILES=()
cleanup() {
    local rc=$?
    if [ "$rc" -eq 0 ] && [ -n "${WORKDIR:-}" ] && [ -d "${WORKDIR}" ]; then
        rm -rf "${WORKDIR}"
    fi
    for f in "${TMP_FILES[@]:-}"; do
        [ -n "$f" ] && [ -e "$f" ] && rm -f -- "$f"
    done
    mkdir -p /aptly/incoming
    find /aptly/incoming -mindepth 1 -maxdepth 1 -type d -mtime +1 -print -exec rm -rf {} + 2>/dev/null || true
}
trap cleanup EXIT

new_tmp() {
    local f
    f=$(mktemp)
    TMP_FILES+=("$f")
    printf '%s\n' "$f"
}

exact_conflict_paths() {
    local logfile="$1"
    grep -E 'error linking file to /[^:]+: file already exists and is different' "$logfile" \
        | sed -E 's/^.*error linking file to (\/[^:]+): file already exists.*/\1/' \
        | grep -E '\.(orig\.tar|tar)\.(gz|xz|bz2|zst)$|\.(deb|ddeb|udeb)$' \
        | sort -u || true
}

run_with_conflict_retry() {
    local label="$1"
    shift
    local log1 log2 rc
    log1=$(new_tmp)

    echo "[${label}] running..."
    set +e
    "$@" 2>&1 | tee "$log1"
    rc=${PIPESTATUS[0]}
    set -e

    local stale
    stale=$(exact_conflict_paths "$log1")
    if [ -n "$stale" ]; then
        echo "[${label}] removing exact stale conflict files..."
        while IFS= read -r path; do
            [ -n "$path" ] || continue
            echo "  Removing: $path"
            rm -f -- "$path"
        done <<< "$stale"

        log2=$(new_tmp)
        echo "[${label}] retrying after conflict cleanup..."
        set +e
        "$@" 2>&1 | tee "$log2"
        rc=${PIPESTATUS[0]}
        set -e
    fi

    if [ "$rc" -ne 0 ]; then
        echo "ERROR: ${label} failed (exit ${rc})" >&2
        return "$rc"
    fi
}


cd "${WORKDIR}"

changes_files=( *.changes )
if [ "${#changes_files[@]}" -ne 1 ]; then
    echo "------------------------------------"
    echo "Processing: ${SPKG:-} (no .changes yet)"
    echo "DIST=${DIST}"
    echo "REPO=${REPO}"
    echo "DIR=${WORKDIR}"
    echo "------------------------------------"
    echo "ERROR: expected exactly 1 .changes file in ${WORKDIR}, found ${#changes_files[@]}" >&2
    if [ "${#changes_files[@]}" -gt 0 ]; then
        printf '  %s\n' "${changes_files[@]}" >&2
    fi
    exit 1
fi
CHANGES_FILE="${changes_files[0]}"
CHANGES_DIST=$(awk -F': ' '/^Distribution:/ {print $2; exit}' "${CHANGES_FILE}" | awk '{print $1}')
CHANGES_ARCH=$(awk -F': ' '/^Architecture:/ {print $2; exit}' "${CHANGES_FILE}")

echo "------------------------------------"
echo "Processing: ${SPKG:-}"
echo "DIST=${DIST}"
echo "REPO=${REPO}"
echo "ARCH=${CHANGES_ARCH:-<unknown>}"
echo "DELETE=${DELETE:-}"
echo "CREATE=${CREATE:-}"
echo "DIR=${WORKDIR}"
echo "LOCK=${LOCKFILE}"
echo "------------------------------------"
if [ -z "${CHANGES_DIST}" ] || [ "${CHANGES_DIST}" != "${DIST}" ]; then
    echo "ERROR: changes distribution ${CHANGES_DIST:-<empty>} does not match requested DIST=${DIST}" >&2
    exit 1
fi
for f in *.deb *.dsc *.buildinfo *.changes; do
    [ -e "${f}" ] || continue
    case "${f}" in
        *"~${DIST}"*) ;;
        *)
            echo "ERROR: incoming file does not match requested DIST=${DIST}: ${f}" >&2
            exit 1
            ;;
    esac
done

if [ "${CREATE:-}" = "YES" ]; then
    if ! aptly repo list -raw 2>/dev/null | grep -Fxq "${REPO}"; then
        aptly repo create -distribution="${DIST}" -component=main "${REPO}"
    fi
fi

# DELETE-then-IMPORT (restored 2026-05-31). Wipe the whole source package and
# all its (sub)binaries from the repo FIRST, in a single removal, then import
# the fresh .changes. This is the original, predictable flow: it does not
# depend on which arch's debs happen to be in this dir, so dual-arch uploads no
# longer leave the index in a half-consistent state. The add-first/prune-the-
# complement variant (May 28 .. May 31) computed its keep-set from only the
# current invocation's debs and removed by un-arch-qualified Package(name),
# which is what produced the inconsistent indices + extra republish windows
# that surfaced as "File has unexpected size" on concurrent builds.
if [ "${DELETE:-}" = "YES" ] && [ -n "${SPKG:-}" ]; then
    echo "Removing ${SPKG} (\$Source ${SPKG}) before import"
    aptly repo remove "${REPO}" "\$Source (${SPKG})" || true
fi

run_with_conflict_retry repo-include \
    aptly -architectures=amd64,arm64,all -repo="${REPO}" -accept-unsigned -ignore-signatures -force-replace repo include "${CHANGES_FILE}"

if [ "${CREATE:-}" = "YES" ]; then
    if ! aptly publish list --raw 2>/dev/null | awk -v repo="filesystem:${REPO}:." -v dist="${DIST}" '$1 == repo && $2 == dist { found=1 } END { exit(found ? 0 : 1) }'; then
        aptly -architectures=amd64,arm64,all publish repo -origin=deb.myguard.nl -label=deb.myguard.nl -gpg-key=67F9C3D8456D7F62 "${REPO}" "filesystem:${REPO}:."
    fi
fi

run_with_conflict_retry publish-update \
    aptly -architectures=amd64,arm64,all publish update -gpg-key=67F9C3D8456D7F62 "${DIST}" "filesystem:${REPO}:."

if [ -f /aptly/bin/dbcleanupcounter.sh ]; then
    /aptly/bin/dbcleanupcounter.sh
elif [ -f /aptly/examples/dbcleanupcounter.sh ]; then
    /aptly/examples/dbcleanupcounter.sh
fi
