FROM    eilandert/ubuntu-base:rolling
LABEL   maintainer="Thijs Eilander <eilander@myguard.nl>"
ENV     DEBIAN_FRONTEND="noninteractive"

COPY    bootstrap.sh /bootstrap.sh

RUN     . /etc/os-release \
        && echo "deb [trusted=yes] http://ppa.launchpad.net/eilander/backports/ubuntu ${UBUNTU_CODENAME} main" > /etc/apt/sources.list.d/eilander-ubuntu-backports-${UBUNTU_CODENAME}.list \
        && apt-get update && apt-get -y upgrade \
        && apt-get -y --no-install-recommends install \
		dovecot-core \
		dovecot-imapd \
		dovecot-lmtpd \
		dovecot-managesieved \
		dovecot-mysql \
		dovecot-pgsql \
		dovecot-pop3d \
		dovecot-sieve \
		dovecot-submissiond \
		syslog-ng-core \
        && apt-get -y autoremove && apt-get -y autoclean && rm -rf /var/lib/apt/lists/* \
        && mv /etc/dovecot /etc/dovecot.orig && mkdir -p /etc/dovecot \
        && chmod +x /bootstrap.sh

COPY syslog-ng.conf /etc/syslog-ng


EXPOSE 24 143 110 993 995 4190

CMD [ "/bootstrap.sh" ]

