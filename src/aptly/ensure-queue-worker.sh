#!/bin/bash
#
# ensure-queue-worker.sh — start aptly-queue-worker.sh if it isn't running.
#
# Called from the enqueue path (a build SSHes in, drops a job dir, then runs
# this) so a dead worker self-heals the moment new work arrives — no idle
# supervisor process, no 30-minute build hang when the worker has crashed.
#
# Safe to call on every enqueue: the test-acquire below is non-blocking, and the
# worker's own `flock -n` start guard means at most one worker ever runs even if
# two enqueues race here. Idempotent.
#
set -euo pipefail

WORKER="${APTLY_QUEUE_WORKER:-/aptly/bin/aptly-queue-worker.sh}"
WORKER_LOCK="/tmp/aptly-queue-worker.lock"
LOG="${APTLY_QUEUE_LOG:-/aptly/queue-worker.log}"

# Prefer the runtime copy in /aptly/bin (writable, may carry hot fixes); fall
# back to the image copy.
[ -x "${WORKER}" ] || WORKER="/usr/local/bin/aptly-queue-worker.sh"

# Is a worker holding the lock? flock -n test-acquires on fd 9 WITHOUT holding it
# (the subshell exits immediately, releasing). Success => lock was free => no
# live worker => start one. Failure => a worker (or its inotifywait child) holds
# it => nothing to do.
if flock -n 9; then
    echo "[ensure-worker $(date -u +%FT%TZ)] no worker holding ${WORKER_LOCK}; starting ${WORKER}" >> "${LOG}"
    setsid bash -c "exec '${WORKER}' >> '${LOG}' 2>&1" </dev/null &
    disown 2>/dev/null || true
fi 9>"${WORKER_LOCK}"
