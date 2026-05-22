# syntax=docker/dockerfile:1.7
FROM alpine:3.12
LABEL org.opencontainers.image.authors="eilandert"
LABEL org.opencontainers.image.source="https://github.com/eilandert/dockerized"

LABEL maintainer="Thijs Eilander <eilander@myguard.nl>"

RUN  apk update && apk upgrade \
  && apk add --no-cache unbound bind-tools tzdata \
  && chown root:unbound /etc/unbound \
  && chmod 775 /etc/unbound \
  && /usr/sbin/unbound-anchor -a /etc/unbound/trusted-key.key | true \
  && rm -rf /var/cache/apk/* /usr/src/*

EXPOSE 53/udp
EXPOSE 53/tcp

COPY config.orig /config.orig
COPY --chmod=0755 bootstrap.sh /bootstrap.sh
RUN chmod +x /bootstrap.sh

HEALTHCHECK --interval=30s --timeout=5s --start-period=15s --retries=3 CMD unbound-control status > /dev/null 2>&1 || dig @127.0.0.1 +time=2 +tries=1 +short . NS > /dev/null || exit 1

CMD ["/bootstrap.sh"]

