FROM    eilandert/php-fpm:multi
LABEL   maintainer="Thijs Eilander <eilander@myguard.nl>"
ENV     DEBIAN_FRONTEND="noninteractive"

COPY    bootstrap-php.sh /bootstrap.sh

RUN     . /etc/os-release \
        && echo "deb [trusted=yes] http://ppa.launchpad.net/eilander/nginx/ubuntu ${UBUNTU_CODENAME} main" > /etc/apt/sources.list.d/eilander-ubuntu-nginx-${UBUNTU_CODENAME}.list \
        && apt-get update && apt-get -y upgrade \
        && apt-get -y --no-install-recommends install \
                nginx-full \
                libmodsecurity3 \
                libnginx-mod-modsecurity \
                libnginx-mod-pagespeed \
                libnginx-mod-security-headers \
                libnginx-mod-brotli \
                libnginx-mod-ssl-ct \
                modsecurity-crs \
        && apt-get -y autoremove && apt-get -y autoclean && rm -rf /var/lib/apt/lists/* \
        && mv /etc/nginx /etc/nginx.orig && mkdir -p /etc/nginx \
        && mv /etc/modsecurity /etc/modsecurity.orig && mkdir -p /etc/modsecurity \
        && chmod +x /bootstrap.sh


CMD     ["/bootstrap.sh"]
EXPOSE  80 80
EXPOSE  443 443

