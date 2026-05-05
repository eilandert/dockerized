FROM    eilandert/ubuntu-base:focal
LABEL org.opencontainers.image.authors="eilandert"
LABEL org.opencontainers.image.source="https://github.com/eilandert/dockerized"

LABEL   maintainer="Thijs Eilander <eilander@myguard.nl>"
ENV     DEBIAN_FRONTEND="noninteractive"
ENV     TZ=Europe/Amsterdam

COPY bootstrap.sh /bootstrap.sh

RUN    chmod +x /bootstrap.sh
WORKDIR /usr/src

CMD     ["/bootstrap.sh"]


