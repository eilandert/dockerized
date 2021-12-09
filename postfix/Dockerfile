# This file might be outdated, see https://github.com/eilandert/dockerized for a recent one
FROM    eilandert/ubuntu-base:rolling
LABEL   maintainer="Thijs Eilander <eilander@myguard.nl>"
ENV     DEBIAN_FRONTEND="noninteractive"
ENV	LD_PRELOAD=/usr/lib/mimalloc-2.0/libmimalloc-secure.so
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

CMD [ "/bootstrap.sh" ]

COPY syslog-ng.conf /etc/syslog-ng
EXPOSE 25 587

VOLUME [ "/var/lib/postfix" ]

