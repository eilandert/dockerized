FROM ubuntu:devel

RUN     apt-get update && apt-get install -y --no-install-recommends ca-certificates software-properties-common && apt-get upgrade -y \
	&& add-apt-repository -y ppa:eilander/nginx && apt-get update && apt-get -y upgrade \
	&& apt-get -y purge software-properties-common unattended-upgrades \
	&& apt-get -y --no-install-recommends install nginx-full libmodsecurity3 libnginx-mod-modsecurity modsecurity-crs libnginx-mod-pagespeed \
	&& apt-get -y autoremove && apt-get -y autoclean && rm -rf /var/lib/apt/lists/* \
	&& dpkg-statoverride --update --add root adm 0000 /bin/su \
	&& dpkg-statoverride --update --add root adm 0000 /usr/bin/sudo \
	&& mv /etc/nginx /etc/nginx.orig && mkdir -p /etc/ngix \
	&& mv /etc/modsecurity /etc/modsecurity.orig && mkdir -p /etc/modsecurity

COPY    bootstrap.sh /bootstrap.sh
RUN	chmod +x /bootstrap.sh 
CMD	/bootstrap.sh
EXPOSE	80 80
EXPOSE  443 443
VOLUME "/var/log/nginx"
