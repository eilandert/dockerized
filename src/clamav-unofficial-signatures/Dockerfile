# syntax=docker/dockerfile:1.7
FROM    eilandert/debian-base:trixie
LABEL   org.opencontainers.image.authors="eilandert" \
        org.opencontainers.image.source="https://github.com/eilandert/dockerized" \
        maintainer="Thijs Eilander <eilander@myguard.nl>"
ENV     DEBIAN_FRONTEND="noninteractive"

COPY user.conf /config.orig/clamav-unofficial-sigs/user.conf
COPY --chmod=0755 bootstrap.sh /bootstrap.sh
COPY --chmod=0755 check.sh /check.sh

RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt,sharing=locked \
    set -ex ;\
    rm -f /etc/apt/apt.conf.d/docker-clean ;\
    apt-get update ;\
    apt-get -y --no-install-recommends install bash wget curl rsync tzdata bind9-host bind9-dnsutils ;\
    apt-get -y --no-install-recommends install clamav clamav-daemon clamav-freshclam clamav-milter clamdscan ;\
    mkdir -p /usr/local/sbin/ /config.orig/clamav-unofficial-sigs ;\
    mv /etc/clamav /config.orig ;\
    curl -fsSL https://raw.githubusercontent.com/extremeshok/clamav-unofficial-sigs/master/clamav-unofficial-sigs.sh -o /usr/local/sbin/clamav-unofficial-sigs.sh ;\
    curl -fsSL https://raw.githubusercontent.com/extremeshok/clamav-unofficial-sigs/master/config/master.conf -o /config.orig/clamav-unofficial-sigs/master.conf ;\
    curl -fsSL https://raw.githubusercontent.com/extremeshok/clamav-unofficial-sigs/master/config/os/os.ubuntu.conf -o /config.orig/clamav-unofficial-sigs/os.conf ;\
    chmod +x /usr/local/sbin/clamav-unofficial-sigs.sh ;\
    apt-get -y autoremove ;\
    sed -i /Proxy/d /config.orig/clamav/freshclam.conf ;\
    sed -i /^#/d /config.orig/clamav/*.conf ;\
    sed -i s/work_dir_urlhaust/work_dir_urlhaus/ /usr/local/sbin/clamav-unofficial-sigs.sh ;\
    echo "background_thread:true,metadata_thp:auto" > /etc/malloc.conf

VOLUME ["/var/lib/clamav"]
EXPOSE 3310/tcp

HEALTHCHECK --interval=30s --timeout=5s --start-period=15s --retries=3 CMD test -f /var/log/clamav-unofficial-sigs.log && find /var/log/clamav-unofficial-sigs.log -mmin -1440 | grep -q . || exit 1

CMD ["/bootstrap.sh"]
