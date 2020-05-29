FROM alpine:edge
LABEL maintainer="Thijs Eilander <eilander@myguard.nl>"

RUN apk update && apk upgrade && apk add rspamd rspamd-openrc rspamd-client rspamd-controller rspamd-fuzzy rspamd-proxy rspamd-utils gnupg tzdata syslog-ng

COPY bootstrap.sh /bootstrap.sh

RUN     addgroup -S -g 1000 _rspamd && adduser -S -G _rspamd -u 1000 _rspamd \
        && echo 'type = "console";' > /etc/rspamd/override.d/logging.inc \
        && echo 'bind_socket = "*:11334";' > /etc/rspamd/override.d/worker-controller.inc \
        && echo 'pidfile = false;' > /etc/rspamd/override.d/options.inc \
        && chown _rspamd:_rspamd -R /var/lib/rspamd \
        && mv /etc/rspamd /etc/rspamd.orig \
        && chmod +x /bootstrap.sh

COPY syslog-ng.conf /etc/syslog-ng

CMD [ "/bootstrap.sh" ]

EXPOSE 11332 11333 11334
VOLUME  [ "/var/lib/rspamd" ]
