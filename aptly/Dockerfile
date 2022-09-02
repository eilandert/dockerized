FROM    eilandert/ubuntu-base:rolling
LABEL   maintainer="Thijs Eilander <eilander@myguard.nl>"
ENV     DEBIAN_FRONTEND="noninteractive"
ENV     TZ=Europe/Amsterdam
COPY    bootstrap.sh /bootstrap.sh
COPY	ssh-createkeys.sh /ssh-createkeys.sh
COPY    syslog-ng.conf /etc/syslog-ng

RUN set -ex ;\
    # Debian:
    dpkg-statoverride --remove /usr/bin/sudo ;\
    # Ubuntu:
    dpkg-statoverride --remove /bin/sudo ;\
    apt-get update ;\
    apt-get -y --no-install-recommends install \
      aptly \
      ca-certificates \
      less \
      libnginx-mod-http-fancyindex \
      nginx-light \
      openssh-server \
      rsync \
      sudo \
      syslog-ng-core \
      tzdata \
      vim

RUN apt-get -y autoremove && apt-get -y autoclean && rm -rf /var/lib/apt/lists/* ;\
    chmod +x /bootstrap.sh ;\
    mkdir /run/sshd && rm -f /etc/motd ;\
    groupadd -g 1010 aptly ;\
    useradd -u 1010 -g 1010 aptly -s /bin/bash -d /aptly ;\
    rm -f /etc/ssh/ssh_host_rsa_key* ;\
    rm -f /etc/ssh/ssh_host_dsa_key* ;\
    rm -f /etc/ssh/ssh_host_ecdsa_key* ;\ 
    rm -f /etc/ssh/ssh_host_ed25519_key* ;\
    rm -f /etc/nginx/modules-enabled/50-mod-http-echo.conf ;\
    sed -i /^Banner/d /etc/ssh/sshd_config.d/20-security.conf ;\
    sed -i s/"^#Password"/"Password"/ /etc/ssh/sshd_config.d/20-security.conf ;\
    sed -i s/"#AllowGroups"/"AllowGroups"/ /etc/ssh/sshd_config.d/20-security.conf ;\
    addgroup ssh-users && usermod -L -a -G ssh-users aptly ;\
    cp -rp /etc/ssh /etc/ssh.orig

RUN apt-get install -y cis-hardening ;\
    cd /opt/cis-hardening ;\
    bin/hardening.sh --set-hardening-level 4 --allow-unsupported-distribution --audit ;\
    bin/hardening.sh --allow-unsupported-distribution --apply ;\
    apt-get purge -y patch cis-hardening ;\
    rm -rf /opt/cis-hardening

RUN \
	chmod 644 /etc/syslog-ng/syslog-ng.conf ;\
	chmod 666 /etc/syslog-ng/conf.d/

CMD [ "/bootstrap.sh" ]

COPY default-vhost.nginx /etc/nginx/sites-enabled/default
COPY examples /aptly.orig/examples

EXPOSE 22 80
WORKDIR /aptly
VOLUME /etc/ssh  #otherwise ssh serverkeys will change on each pull

