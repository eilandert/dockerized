FROM    eilandert/apache-phpfpm:8.0
LABEL   maintainer="Thijs Eilander <eilander@myguard.nl>"
ENV     DEBIAN_FRONTEND="noninteractive"

# include the wait-for-it.sh script
ADD	https://raw.githubusercontent.com/vishnubob/wait-for-it/master/wait-for-it.sh /wait-for-it.sh
COPY	bootstrap.sh /

ENV	INSTALLDIR="/opt/roundcube"

RUN set -ex; \
	apt-get -qq update; \
	rm -rf /etc/php && mv /etc/php.orig /etc/php; \
        apt-get install -y --no-install-recommends \
	  php${PHPVERSION}-exif \
	  php${PHPVERSION}-gd \
	  php${PHPVERSION}-intl \
	  php${PHPVERSION}-ldap \
	  php${PHPVERSION}-sqlite \
	  git unzip locales; \
        git clone \
          --recurse-submodules \
          --depth=1 \
          -c advice.detachedHead=false \
          -j`nproc` \
          https://github.com/roundcube/roundcubemail.git \
        ${INSTALLDIR}; \
	rm -rf ${INSTALLDIR}/installer; \
	chown -R www-data:www-data ${INSTALLDIR}/logs; \
        cd ${INSTALLDIR};\
        mv composer.json-dist composer.json; \
        composer install --prefer-dist --no-dev; \
	composer update --prefer-dist --no-dev; \
	composer config -g secure-http false; \
	echo "php_admin_flag[opcache.enable] = 1" >> /etc/php/${PHPVERSION}/fpm/pool.d/www.conf; \
	echo "php_admin_value[opcache.jit_buffer_size]=100M" >> /etc/php/${PHPVERSION}/fpm/pool.d/www.conf; \
        mv /etc/php /etc/php.orig && mkdir /etc/php; \
	chmod +x /wait-for-it.sh; \
	chmod +x /bootstrap.sh; \
	mkdir -p /var/roundcube/config; \
	echo "Include /var/roundcube/config/httpd.conf" > /etc/apache2.orig/sites-enabled/000-default.conf; \
	apt-get -y purge git unzip mailutils nullmailer; \
	apt-get -y autoremove && apt-get -y clean && apt-get -y autoclean; \
        rm -rf /var/lib/apt/lists/*

COPY httpd.conf /var/roundcube/config


ENTRYPOINT ["/bootstrap.sh"]

# expose these volumes
VOLUME /var/roundcube/config
VOLUME /var/roundcube/db


