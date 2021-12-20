FROM    eilandert/debian-base:stable
LABEL   maintainer="Thijs Eilander <eilander@myguard.nl>"
ENV     DEBIAN_FRONTEND="noninteractive"
ENV     TZ=Europe/Amsterdam
COPY    bootstrap.sh /bootstrap.sh
COPY	ssh-createkeys.sh /ssh-createkeys.sh

RUN set -ex ;\
    dpkg-statoverride --remove /usr/bin/sudo ;\
    dpkg-statoverride --remove /bin/sudo ;\
    apt-get update ;\
    apt-get -y --no-install-recommends install \
    aptly \
    ca-certificates \
    nginx-light \
    libnginx-mod-http-fancyindex \
    openssh-server \
    rsync \
    sudo \
    syslog-ng-core \
    tzdata

RUN apt-get install -y cis-hardening ;\
    cd /opt/cis-hardening ;\
    bin/hardening.sh --set-hardening-level 4 --allow-unsupported-distribution --audit ;\
    bin/hardening.sh --allow-unsupported-distribution --apply ;\
    apt-get purge -y patch cis-hardening ;\
    rm -rf /opt/cis-hardening

RUN apt-get -y autoremove && apt-get -y autoclean && rm -rf /var/lib/apt/lists/* ;\
    chmod +x /bootstrap.sh ;\
    mkdir /run/sshd && rm -f /etc/motd ;\
    groupadd -g 1010 aptly ;\
    useradd -u 1010 -g 1010 aptly -s /bin/bash -d /aptly ;\
    mkdir -p /aptly.orig/config ;\
    rm -f /etc/ssh/ssh_host_rsa_key* ;\
    rm -f /etc/ssh/ssh_host_dsa_key* ;\
    rm -f /etc/ssh/ssh_host_ecdsa_key* ;\ 
    rm -f /etc/ssh/ssh_host_ed25519_key* ;\
    rm -f /etc/nginx/modules-enabled/50-mod-http-echo.conf

CMD [ "/bootstrap.sh" ]

COPY syslog-ng.conf /etc/syslog-ng
COPY default-vhost.nginx /etc/nginx/sites-enabled/default
COPY examples /aptly.orig/examples

EXPOSE 22 80
WORKDIR /aptly
