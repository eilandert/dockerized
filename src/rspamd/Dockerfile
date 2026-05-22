# syntax=docker/dockerfile:1.7
FROM alpine:edge
LABEL   org.opencontainers.image.authors="eilandert" \
        org.opencontainers.image.source="https://github.com/eilandert/dockerized" \
        maintainer="Thijs Eilander <eilander@myguard.nl>"

COPY --chmod=0755 bootstrap.sh /bootstrap.sh
COPY syslog-ng.conf /etc/syslog-ng

RUN --mount=type=cache,target=/var/cache/apk,sharing=locked \
    set -eux ;\
    apk update && apk upgrade ;\
    apk add --no-cache rspamd rspamd-openrc rspamd-client rspamd-controller rspamd-fuzzy rspamd-proxy rspamd-utils gnupg tzdata syslog-ng ;\
    addgroup -S -g 1000 _rspamd && adduser -S -G _rspamd -u 1000 _rspamd ;\
    echo 'type = "console";'                > /etc/rspamd/override.d/logging.inc ;\
    echo 'bind_socket = "*:11334";'         > /etc/rspamd/override.d/worker-controller.inc ;\
    echo 'pidfile = false;'                 > /etc/rspamd/override.d/options.inc ;\
    chown -R _rspamd:_rspamd /var/lib/rspamd ;\
    mv /etc/rspamd /etc/rspamd.orig

VOLUME ["/var/lib/rspamd"]
EXPOSE 11332 11333 11334

HEALTHCHECK --interval=30s --timeout=5s --start-period=15s --retries=3 CMD rspamadm control stat > /dev/null 2>&1 || curl -fsS --max-time 3 http://127.0.0.1:11334/stat > /dev/null || exit 1

CMD ["/bootstrap.sh"]
