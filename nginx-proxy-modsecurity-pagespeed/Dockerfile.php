FROM	eilandert/ubuntu-base:rolling
LABEL	maintainer="Thijs Eilander <eilander@myguard.nl>"
ENV	DEBIAN_FRONTEND="noninteractive"

COPY    bootstrap-php.sh /bootstrap.sh

RUN     UBUNTU=`lsb_release -c -s` \
	&& echo "deb [trusted=yes] http://ppa.launchpad.net/eilander/nginx/ubuntu ${UBUNTU} main" > /etc/apt/sources.list.d/eilander-ubuntu-nginx-${UBUNTU}.list \
        && echo "deb [trusted=yes] http://ppa.launchpad.net/ondrej/php/ubuntu ${UBUNTU} main" > /etc/apt/sources.list.d/ondrej-ubuntu-php-${UBUNTU}.list \
	&& apt-get update && apt-get -y upgrade \
        && apt-get install -y nullmailer mailutils \
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

ENV     PHPVERSION=5.6
RUN     apt-get update && apt-get -y upgrade \
	&& apt-get install -y --no-install-recommends \
                php${PHPVERSION} \
                php${PHPVERSION}-fpm \
                php${PHPVERSION}-apcu \
                php${PHPVERSION}-bcmath \
                php${PHPVERSION}-cli \
                php${PHPVERSION}-curl \
                php${PHPVERSION}-dom \
                php${PHPVERSION}-gd \
                php${PHPVERSION}-igbinary \
                php${PHPVERSION}-imagick \
                php${PHPVERSION}-json \
                php${PHPVERSION}-memcached \
                php${PHPVERSION}-mbstring \
                php${PHPVERSION}-mcrypt \
                php${PHPVERSION}-mysql \
                php${PHPVERSION}-opcache \
                php${PHPVERSION}-pgsql \
                php${PHPVERSION}-readline \
                php${PHPVERSION}-recode \
                php${PHPVERSION}-redis \
                php${PHPVERSION}-soap \
                php${PHPVERSION}-tidy \
                php${PHPVERSION}-xml \
                php${PHPVERSION}-zip \
        && apt-get -y autoremove && apt-get -y autoclean

ENV     PHPVERSION=7.4
RUN     apt-get update && apt-get -y upgrade \
        && apt-get install -y --no-install-recommends \
                php${PHPVERSION} \
                php${PHPVERSION}-fpm \
                php${PHPVERSION}-apcu \
                php${PHPVERSION}-bcmath \
                php${PHPVERSION}-cli \
                php${PHPVERSION}-curl \
                php${PHPVERSION}-dom \
                php${PHPVERSION}-gd \
                php${PHPVERSION}-igbinary \
                php${PHPVERSION}-imagick \
                php${PHPVERSION}-json \
                php${PHPVERSION}-memcached \
                php${PHPVERSION}-mbstring \
#               php${PHPVERSION}-mcrypt \
                php${PHPVERSION}-mysql \
                php${PHPVERSION}-opcache \
                php${PHPVERSION}-pgsql \
                php${PHPVERSION}-readline \
#               php${PHPVERSION}-recode \
                php${PHPVERSION}-redis \
                php${PHPVERSION}-soap \
                php${PHPVERSION}-tidy \
                php${PHPVERSION}-xml \
                php${PHPVERSION}-zip \
        && apt-get -y autoremove && apt-get -y autoclean

ENV     PHPVERSION=8.0
RUN     apt-get update && apt-get -y upgrade \
        && apt-get install -y --no-install-recommends \
                php${PHPVERSION} \
                php${PHPVERSION}-fpm \
                php${PHPVERSION}-apcu \
                php${PHPVERSION}-bcmath \
                php${PHPVERSION}-cli \
                php${PHPVERSION}-curl \
                php${PHPVERSION}-dom \
                php${PHPVERSION}-gd \
                php${PHPVERSION}-igbinary \
                php${PHPVERSION}-imagick \
#                php${PHPVERSION}-json \
                php${PHPVERSION}-memcached \
                php${PHPVERSION}-mbstring \
#               php${PHPVERSION}-mcrypt \
                php${PHPVERSION}-mysql \
                php${PHPVERSION}-opcache \
                php${PHPVERSION}-pgsql \
                php${PHPVERSION}-readline \
#               php${PHPVERSION}-recode \
                php${PHPVERSION}-redis \
                php${PHPVERSION}-soap \
                php${PHPVERSION}-tidy \
                php${PHPVERSION}-xml \
                php${PHPVERSION}-zip \
        && apt-get -y autoremove && apt-get -y autoclean

RUN     mv /etc/php /etc/php.orig && mkdir -p /etc/php \
        && mv /etc/nullmailer /etc/nullmailer.orig && mkdir -p /etc/nullmailer \
        && apt-get -y autoremove && apt-get -y autoclean \
        && rm -rf /var/lib/apt/lists/*

CMD	["/bootstrap.sh"]
EXPOSE	80 80
EXPOSE  443 443
