FROM    eilandert/ubuntu-base:rolling
LABEL   maintainer="Thijs Eilander <eilander@myguard.nl>"
ENV     DEBIAN_FRONTEND="noninteractive"

COPY    bootstrap.sh /bootstrap.sh

RUN set -ex ;\
    apt-get update ;\
    apt-get -y --no-install-recommends install \
      nginx-extras \
         libnginx-mod-brotli \
         libnginx-mod-http-auth-pam \
         libnginx-mod-http-auth-spnego \
         libnginx-mod-http-cache-purge \
         libnginx-mod-http-dav-ext \
         libnginx-mod-http-doh \
         libnginx-mod-http-echo \
	 libnginx-mod-http-encrypted-session \
         libnginx-mod-http-fancyindex \
         libnginx-mod-http-geoip \
         libnginx-mod-http-geoip2 \
         libnginx-mod-http-headers-more-filter \
         libnginx-mod-http-image-filter \
         libnginx-mod-http-lua \
	 libnginx-mod-http-lua-ssl \
	 libnginx-mod-http-njs \
         libnginx-mod-http-ndk \
         libnginx-mod-http-perl \
	 libnginx-mod-http-redis2 \
         libnginx-mod-http-subs-filter \
	 libnginx-mod-http-trim-filter \
         libnginx-mod-http-uploadprogress \
         libnginx-mod-http-upstream-fair \
         libnginx-mod-http-xslt-filter \
         libnginx-mod-mail \
         libnginx-mod-modsecurity \
         libnginx-mod-nchan \
         libnginx-mod-pagespeed \
         libnginx-mod-rtmp \
         libnginx-mod-security-headers \
         libnginx-mod-ssl-ct \
         libnginx-mod-stream \
         libnginx-mod-stream-geoip \
         libnginx-mod-stream-geoip2 \
	 libnginx-mod-stream-lua \
         libnginx-mod-vts \
      libmodsecurity3 \
      lua-resty \
      modsecurity-crs \
      curl \
      mimalloc \
      libjemalloc2 \
      geoip-bin fcgiwrap ssl-cert \
      brotli \
      ;\
    apt-get -y autoremove && apt-get -y autoclean && rm -rf /var/lib/apt/lists/* ;\
    mv /etc/nginx /etc/nginx.orig && mkdir -p /etc/nginx ;\
    mv /etc/modsecurity /etc/modsecurity.orig && mkdir -p /etc/modsecurity ;\
    chmod +x /bootstrap.sh ;\
    rm -f /var/spool/nullmailer/trigger ;\
    echo "background_thread:true,metadata_thp:auto" > /etc/malloc.conf

CMD     ["/bootstrap.sh"]
EXPOSE  80 80
EXPOSE  443 443

WORKDIR /etc/nginx
