#!/bin/sh
# Container healthcheck = liveness + readiness.
#   Liveness:  angie answers on the loopback healthz vhost (127.0.0.1:8181).
#   Readiness: php-fpm actually ANSWERS a FastCGI request — curl /fpm-ping, which
#              fastcgi_passes to the pool's ping.path (=> "pong"). A real round
#              trip: fails on a dead master, a stale socket, OR a wedged pool —
#              none of which a "socket file exists" check would catch.
set -eu
curl -fsS --max-time 3 -o /dev/null http://127.0.0.1:8181/healthz || exit 1
if ! curl -fsS --max-time 3 http://127.0.0.1:8181/fpm-ping 2>/dev/null | grep -q pong; then
    echo "readiness: php-fpm did not answer /fpm-ping (master dead / pool wedged / stale socket)" >&2
    exit 1
fi
exit 0
