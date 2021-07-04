FROM alpine:3.12
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
COPY bootstrap.sh /bootstrap.sh
RUN chmod +x /bootstrap.sh

CMD ["/bootstrap.sh"]

HEALTHCHECK CMD dig @127.0.0.1 || exit 1
