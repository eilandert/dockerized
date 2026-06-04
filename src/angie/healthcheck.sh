#!/bin/sh
# Container healthcheck = liveness + readiness.
#
# Liveness:  angie answers on the loopback healthz vhost (127.0.0.1:8181).
# Readiness: on PHP-enabled images (PHPVERSION inherited from the php-fpm base),
#            at least one php-fpm socket must be present and listening in
#            /run/php — catches "angie up but PHP dead". Non-PHP images skip
#            this check entirely.
set -eu

# --- liveness ---
curl -fsS --max-time 3 -o /dev/null http://127.0.0.1:8181/healthz || exit 1

# --- readiness (PHP images only) ---
if [ -n "${PHPVERSION:-}" ]; then
    # A running php-fpm leaves a unix socket in /run/php. Require at least one.
    sock=$(ls /run/php/*.sock 2>/dev/null | head -n1 || true)
    [ -n "${sock}" ] && [ -S "${sock}" ] || {
        echo "readiness: no php-fpm socket in /run/php" >&2
        exit 1
    }
fi

exit 0
