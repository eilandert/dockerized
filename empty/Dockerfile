FROM alpine:edge

LABEL org.opencontainers.image.authors="eilandert"
LABEL org.opencontainers.image.source="https://github.com/eilandert/dockerized"

COPY bootstrap.sh /bootstrap.sh

RUN apk update && apk upgrade && chmod 755 /bootstrap.sh


CMD ["/bootstrap.sh"]

