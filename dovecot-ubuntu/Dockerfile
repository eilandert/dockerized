# This file might be outdated, see https://github.com/eilandert/dockerized for a recent one
FROM eilandert/ubuntu-base:devel 
LABEL maintainer="Thijs Eilander <eilander@myguard.nl>" 
ENV DEBIAN_FRONTEND="noninteractive"

COPY    bootstrap.sh /bootstrap.sh

RUN set -ex ;\
    . /etc/os-release ;\
    echo "deb [trusted=yes] http://ppa.launchpad.net/eilander/backports/ubuntu ${UBUNTU_CODENAME} main" > /etc/apt/sources.list.d/eilander-ubuntu-backports-${UBUNTU_CODENAME}.list ;\
    apt-get update ;\
    apt-get -y --no-install-recommends install \
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
      libfilesys-diskspace-perl \
      libdbd-mariadb-perl \
      libdbd-pgsql \
      libdbd-mysql-perl \
      libdbd-mysql \
      pyzor \
      razor \
      rspamd \
      spamc \
      curl ;\
    mkdir -p /opt/scripts/vimbadmin.orig ;\
    curl -fSL https://github.com/gibzer/vimbadmin-perl/archive/master.tar.gz |\
      tar xz --strip-components=1 -C /opt/scripts/vimbadmin.orig ;\
    dpkg -i /opt/scripts/vimbadmin.orig/libfilesys-diskusage-perl_0.09-1_all.deb ;\
    rm /opt/scripts/vimbadmin.orig/*.deb ;\
    apt-get -y purge curl ;\
    apt-get -y autoremove && apt-get -y clean && apt-get -y autoclean && rm -rf /var/lib/apt/lists/* ;\
    mv /etc/dovecot /etc/dovecot.orig && mkdir -p /etc/dovecot ;\
    addgroup --gid 5000 vmail ;\
    useradd -u 5000 -g 5000 -s /sbin/nologin vmail ;\
    chmod +x /bootstrap.sh 

#ADD https://raw.githubusercontent.com/eilandert/dockerized/master/vimbadmin-ubuntu/EXAMPLES/dovecot-sql.conf.ext /etc/dovecot.orig
ADD syslog-ng.conf /etc/syslog-ng

WORKDIR /etc/dovecot

EXPOSE 24 143 110 993 995 4190

CMD [ "/bootstrap.sh" ]
