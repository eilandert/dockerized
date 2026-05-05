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

CMD "/bootstrap.sh"

