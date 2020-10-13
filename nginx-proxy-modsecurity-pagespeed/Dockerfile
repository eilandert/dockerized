FROM	eilandert/ubuntu-base:latest
LABEL	maintainer="Thijs Eilander <eilander@myguard.nl>"
ENV	DEBIAN_FRONTEND="noninteractive"

COPY    bootstrap.sh /bootstrap.sh

RUN     add-apt-repository -y ppa:eilander/nginx \
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
        && apt-get -y purge software-properties-common unattended-upgrades \
	&& apt-get -y autoremove && apt-get -y autoclean && rm -rf /var/lib/apt/lists/* \
	&& mv /etc/nginx /etc/nginx.orig && mkdir -p /etc/nginx \
	&& mv /etc/modsecurity /etc/modsecurity.orig && mkdir -p /etc/modsecurity \
	&& chmod +x /bootstrap.sh 

CMD	["/bootstrap.sh"]
EXPOSE	80 80
EXPOSE  443 443
