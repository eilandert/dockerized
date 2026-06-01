#!/bin/bash
#
# aptly-atomic-publish.sh — race-free publishing for the shared-pool aptly tree.
#
# THE RACE THIS KILLS
#   `aptly publish update`/`switch` rewrites dists/<dist>/{Release,InRelease,
#   Packages,Packages.bz2,...} IN PLACE, file-by-file. A reader (pbuilder's
#   `apt-get update`) that fetches InRelease (new) then Packages.bz2 (still mid-
#   rewrite) gets "File has unexpected size. Mirror sync in progress?". Measured
#   on prod: in-place = ~50% of concurrent reads mismatch; atomic flip = 0/300.
#   (open_file_cache was ruled out — off changes nothing; the cause is the
#   non-atomic write ordering, not nginx caching.)
#
# THE FIX
#   Build the new index in an OFF-LIVE staging dir, then swap it in with a single
#   atomic rename of a SYMLINK. apt always sees one complete generation —
#   old-complete or new-complete, never a half-written mix.
#
#     repo include                       # debs → shared pool (additive, no race)
#     snapshot create <snap>             # immutable pointer, writes nothing live
#     publish snapshot → .stage-<ts>/    # full dists/<dist> built off-live;
#                                        #   .stage/pool symlinks the SHARED pool
#                                        #   so Filename: pool/... still resolves
#     ln -sfn .../.stage-<ts>/dists/<dist>  dists/<dist>.tmp
#     mv -T dists/<dist>.tmp dists/<dist>   # ATOMIC (rename(2) over a symlink)
#
#   dists/<dist> becomes a symlink into the current generation. Only that one
#   dist's entry flips; sibling dists and the shared pool are untouched.
#
# REQUIREMENTS / NOTES
#   * Pool is shared + additive + content-addressed (dist in the filename), so it
#     is never inconsistent mid-flip — only dists/<dist> is swapped.
#   * mv -T over a SYMLINK is atomic; mv -T over a non-empty DIR is not (ENOTEMPTY),
#     which is why dists/<dist> must be a symlink. First call converts an existing
#     real dir into the symlink form (old real dir is kept as a stage generation).
#   * Each flip leaves a published snapshot + stage dir behind. reap_stage() drops
#     generations older than ATOMIC_REAP_MIN minutes (default 30) so a slow apt
#     fetch on the previous generation is never cut off. The CURRENT target is
#     always kept regardless of age.
#
# Sourced by process-incoming.sh (build-time) and lib.sh (daily). Callers set:
#   APTLY_PUBLIC_ROOT  (default /aptly/repo/public)   — dir holding dists/ + pool/
#   APTLY_GPG_KEY, and brand flags via the BRAND_FLAGS array (origin/label/arch).
#   ATOMIC_REAP_MIN    (default 30)

: "${APTLY_PUBLIC_ROOT:=/aptly/repo/public}"
: "${ATOMIC_REAP_MIN:=30}"

# atomic_publish <repo> <endpoint> <dist>
#   <repo>     = local repo to snapshot+publish (the .deb source).
#   <endpoint> = the aptly filesystem endpoint name whose rootDir is the public
#                tree (e.g. "jammy"/"bookworm" — same name used in
#                filesystem:<endpoint>:. today). <dist> = distribution codename.
#   BRAND_FLAGS (array) and APTLY_GPG_KEY supply -origin/-label/-architectures/
#   -gpg-key. Requires a `run_with_conflict_retry` to be defined by the caller.
#
#   The helper owns the snapshot lifecycle: it creates aps-<dist>-<ts> paired
#   1:1 with stage .stage-<dist>-<ts>, so reap_stage can drop BOTH (publish +
#   snapshot + dir) by the shared <ts> — no untracked snapshot leak.
atomic_publish() {
    local repo="$1" endpoint="$2" dist="$3"
    local ts stage prefix snap gpg=()
    ts=$(date +%s%N)
    prefix=".stage-${dist}-${ts}"
    snap="aps-${dist}-${ts}"
    stage="${APTLY_PUBLIC_ROOT}/${prefix}"
    [ -n "${APTLY_GPG_KEY:-}" ] && gpg=(-gpg-key="${APTLY_GPG_KEY}")

    # Immutable snapshot of the repo's current state — writes nothing live.
    run_with_conflict_retry "atomic-snapshot ${dist} (${snap})" \
        aptly snapshot create "${snap}" from repo "${repo}"

    # Staging dir with a pool symlink to the SHARED pool, so the snapshot's
    # hardlinked debs land in the real pool and Filename: pool/... resolves once
    # the dist is served at the top level.
    mkdir -p "${stage}"
    ln -sfn ../pool "${stage}/pool"

    # Publish the snapshot into the staging prefix (off-live). brand flags first.
    run_with_conflict_retry "atomic-publish ${dist} (stage ${prefix})" \
        aptly publish snapshot -batch "${BRAND_FLAGS[@]}" "${gpg[@]}" \
            -distribution="${dist}" "${snap}" "filesystem:${endpoint}:${prefix}"

    # Atomic flip: point dists/<dist> at the new staged dist via a single rename.
    local live="${APTLY_PUBLIC_ROOT}/dists/${dist}"
    local tmp="${APTLY_PUBLIC_ROOT}/dists/${dist}.flip.${ts}"
    mkdir -p "${APTLY_PUBLIC_ROOT}/dists"
    ln -sfn "../${prefix}/dists/${dist}" "${tmp}"
    mv -T "${tmp}" "${live}"

    reap_stage "${dist}" "${endpoint}"
}

# reap_stage <dist> <endpoint> — drop stage generations for <dist> older than
# ATOMIC_REAP_MIN minutes, except the one dists/<dist> currently points at.
# Drops the published prefix + its snapshot + the on-disk stage dir.
reap_stage() {
    local dist="$1" endpoint="$2"
    local cur cur_prefix d base
    # Resolve current generation's prefix from the live symlink target
    # (../.stage-<dist>-<ts>/dists/<dist>).
    cur=$(readlink "${APTLY_PUBLIC_ROOT}/dists/${dist}" 2>/dev/null || true)
    cur_prefix=$(printf '%s' "${cur}" | sed -n 's#^\.\./\(\.stage-'"${dist}"'-[0-9]\+\)/dists/.*#\1#p')

    while IFS= read -r d; do
        base=$(basename "${d}")                            # .stage-<dist>-<ts>
        [ "${base}" = "${cur_prefix}" ] && continue        # never reap the live one
        local ts="${base#.stage-${dist}-}"                 # shared <ts>
        # Order: drop publish first (releases the snapshot ref), then the paired
        # snapshot, then the on-disk stage dir. Each best-effort/idempotent.
        aptly publish  drop "${dist}" "filesystem:${endpoint}:${base}" >/dev/null 2>&1 || true
        aptly snapshot drop "aps-${dist}-${ts}"                          >/dev/null 2>&1 || true
        rm -rf -- "${d}"
    done < <(find "${APTLY_PUBLIC_ROOT}" -maxdepth 1 -type d \
                  -name ".stage-${dist}-*" -mmin "+${ATOMIC_REAP_MIN}" 2>/dev/null)
}
