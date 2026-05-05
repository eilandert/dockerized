FROM alpine:edge
LABEL org.opencontainers.image.authors="eilandert"
LABEL org.opencontainers.image.source="https://github.com/eilandert/dockerized"

LABEL maintainer="Thijs Eilander <eilander@myguard.nl>"

COPY bootstrap.sh /bootstrap.sh

RUN  apk update && apk upgrade \
  && apk add --no-cache nginx nginx-mod-http-fancyindex tzdata \
  && chmod +x /bootstrap.sh \
  && mv /etc/nginx /etc/nginx.orig && mkdir -p /etc/nginx \
  && rm -rf /var/cache/apk/* /usr/src/*

EXPOSE 80/TCP

HEALTHCHECK --interval=30s --timeout=3s --start-period=10s --retries=3 CMD curl -f http://localhost/ || exit 1

CMD "/bootstrap.sh"

