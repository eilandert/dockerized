#!/bin/sh
# Container healthcheck = liveness + readiness.
#
# Liveness:  angie answers on the loopback healthz vhost (127.0.0.1:8181).
# Readiness: on PHP images, php-fpm must actually ANSWER a FastCGI request. We
#            curl the healthz vhost's /fpm-ping, which fastcgi_passes to the pool
#            ping.path (=> "pong"). A real round-trip: fails on dead master,
#            stale socket, AND a wedged pool — none of which the old "socket file
#            exists" check caught (that let a 10h all-502 outage report healthy).
set -eu

# --- liveness ---
curl -fsS --max-time 3 -o /dev/null http://127.0.0.1:8181/healthz || exit 1

# --- readiness (PHP images only) ---
if [ -n "${PHPVERSION:-}" ]; then
    if ! curl -fsS --max-time 3 http://127.0.0.1:8181/fpm-ping 2>/dev/null | grep -q pong; then
        echo "readiness: php-fpm did not answer /fpm-ping (master dead / pool wedged / stale socket)" >&2
        exit 1
    fi
fi

exit 0
