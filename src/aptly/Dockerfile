# syntax=docker/dockerfile:1.7
FROM    eilandert/debian-base:stable
LABEL org.opencontainers.image.authors="eilandert"
LABEL org.opencontainers.image.source="https://github.com/eilandert/dockerized"

LABEL   maintainer="Thijs Eilander <eilander@myguard.nl>"
ENV     DEBIAN_FRONTEND="noninteractive"
ENV     TZ=Europe/Amsterdam
COPY --chmod=0755 bootstrap.sh /bootstrap.sh
COPY    ssh-createkeys.sh /ssh-createkeys.sh
COPY    syslog-ng.conf /etc/syslog-ng

RUN set -ex ;\
    # Undo base image's sudo statoverride (mode 0000) so the package install
    # below puts sudo down with normal setuid perms.
    dpkg-statoverride --remove /usr/bin/sudo 2>/dev/null || true ;\
    dpkg-statoverride --remove /bin/sudo     2>/dev/null || true ;\
    apt-get update ;\
    apt-get -y --no-install-recommends install \
      aptly \
      ca-certificates \
      cron \
      gpg-agent \
      less \
      libnginx-mod-http-fancyindex \
      libnginx-mod-http-brotli \
      libnginx-mod-http-zstd \
      nano \
      nginx-minimal \
      openssh-server \
      rsync \
      sudo \
      syslog-ng-core \
      tzdata \
      vim ;\
    chmod +x /bootstrap.sh ;\
    chmod 644 /etc/syslog-ng/syslog-ng.conf ;\
    chmod 755 /etc/syslog-ng/conf.d 2>/dev/null || true ;\
    mkdir -p /run/sshd && rm -f /etc/motd ;\
    groupadd -g 1010 aptly ;\
    useradd -u 1010 -g 1010 aptly -s /bin/bash -d /aptly ;\
    rm -f /etc/ssh/ssh_host_rsa_key* /etc/ssh/ssh_host_dsa_key* \
          /etc/ssh/ssh_host_ecdsa_key* /etc/ssh/ssh_host_ed25519_key* ;\
    rm -f /etc/nginx/modules-enabled/50-mod-http-echo.conf ;\
    if [ -f /etc/ssh/sshd_config.d/20-security.conf ]; then \
        sed -i /^Banner/d /etc/ssh/sshd_config.d/20-security.conf ;\
        sed -i s/"^#Password"/"Password"/   /etc/ssh/sshd_config.d/20-security.conf ;\
        sed -i s/"#AllowGroups"/"AllowGroups"/ /etc/ssh/sshd_config.d/20-security.conf ;\
    fi ;\
    addgroup ssh-users && usermod -L -a -G ssh-users aptly ;\
    cp -rp /etc/ssh /etc/ssh.orig ;\
    cp -rp /etc/nginx /etc/nginx.orig ;\
    apt-get -y autoremove && apt-get -y autoclean && rm -rf /var/lib/apt/lists/*

COPY examples /aptly.orig/examples
COPY default-vhost.nginx /etc/nginx/sites-available/default

VOLUME /etc/ssh
WORKDIR /aptly
EXPOSE 22
EXPOSE 80

HEALTHCHECK --interval=30s --timeout=5s --start-period=15s --retries=3 CMD curl -fsS --max-time 3 -o /dev/null http://127.0.0.1:8080/api/version || exit 1

CMD [ "/bootstrap.sh" ]
