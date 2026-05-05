# This file might be outdated, see https://github.com/eilandert/dockerized for a recent one
FROM    eilandert/ubuntu-base:rolling
LABEL org.opencontainers.image.authors="eilandert"
LABEL org.opencontainers.image.source="https://github.com/eilandert/dockerized"

LABEL   maintainer="Thijs Eilander <eilander@myguard.nl>"
ENV     DEBIAN_FRONTEND="noninteractive"
COPY    bootstrap.sh /bootstrap.sh

RUN set -ex ;\
    apt-get update ;\
    apt-get -y --no-install-recommends install \
      ca-certificates tzdata openssl syslog-ng \
      postfix-cdb \
      postfix-ldap \
      postfix-lmdb \
      postfix-mysql \
      postfix-pcre \
      postfix-pgsql \
      postfix-sqlite \
      postfix \
      mimalloc \
      libjemalloc2 \
      ;\
    apt-get -y autoremove && apt-get -y autoclean && rm -rf /var/lib/apt/lists/* ;\
    mv /etc/postfix /etc/postfix.orig ;\
    chmod +x /bootstrap.sh
VOLUME [ "/var/lib/postfix" ]
EXPOSE 25 587
COPY syslog-ng.conf /etc/syslog-ng

CMD [ "/bootstrap.sh" ]



