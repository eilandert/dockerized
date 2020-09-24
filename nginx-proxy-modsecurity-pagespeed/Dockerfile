FROM	ubuntu:latest

COPY    bootstrap.sh /bootstrap.sh

RUN     apt-get -y update && apt -y upgrade \ 
	&& apt-get install -y --no-install-recommends ca-certificates software-properties-common \
	&& add-apt-repository -y ppa:eilander/nginx && apt-get update && apt-get -y upgrade \
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
	&& dpkg-statoverride --update --add root adm 0000 /bin/su \
	&& mv /etc/nginx /etc/nginx.orig && mkdir -p /etc/nginx \
	&& mv /etc/modsecurity /etc/modsecurity.orig && mkdir -p /etc/modsecurity \
	&& chmod +x /bootstrap.sh

CMD	["/bootstrap.sh"]
EXPOSE	80 80
EXPOSE  443 443
