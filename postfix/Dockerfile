FROM    eilandert/ubuntu-base:rolling
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
      ;\
    apt-get -y autoremove && apt-get -y autoclean && rm -rf /var/lib/apt/lists/* ;\
    mv /etc/postfix /etc/postfix.orig ;\
    chmod +x /bootstrap.sh

CMD [ "/bootstrap.sh" ]

COPY syslog-ng.conf /etc/syslog-ng
EXPOSE 25 587

VOLUME [ "/var/lib/postfix" ]

