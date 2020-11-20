FROM    eilandert/apache-phpfpm:7.4
LABEL   maintainer="Thijs Eilander <eilander@myguard.nl>"
ENV     DEBIAN_FRONTEND="noninteractive"

# include the wait-for-it.sh script
ADD	https://raw.githubusercontent.com/vishnubob/wait-for-it/master/wait-for-it.sh /wait-for-it.sh
COPY	bootstrap.sh /

ENV	INSTALLDIR="/opt/roundcube"

RUN set -x; \
	apt-get -y update; \
        rm -rf /etc/php && mv /etc/php.orig /etc/php; \
        apt-get install -y --no-install-recommends \
	  php${PHPVERSION}-exif \
	  php${PHPVERSION}-gd \
	  php${PHPVERSION}-intl \
	  php${PHPVERSION}-imap \
	  php${PHPVERSION}-ldap \
	  php${PHPVERSION}-sqlite \
	  git \
	  unzip \
	  curl \
	  locales; \
	VERSION=`git ls-remote --ta\gs https://github.com/roundcube/roundcubemail.git | cut -d/ -f3- | sort -t. -nk1,2 -k3 | awk '/^[^{]*$/{version=$1}END{print version}'` ;\
	git clone \
	  --recurse-submodules \
	  --depth=1 \ 
	  -c advice.detachedHead=false \
	  --branch ${VERSION} \
	  https://github.com/roundcube/roundcubemail.git \
          ${INSTALLDIR}; \
        cd ${INSTALLDIR} ;\
        mv composer.json-dist composer.json; \
	composer update --prefer-dist --no-dev ;\
#	composer config -g secure-http false; \
	bin/install-jsdeps.sh ;\
	cd plugins ;\
	for dir in `ls`; do cd $dir; composer update --prefer-dist --no-dev; cd ..; done ;\
	echo "include=/var/roundcube/config/phpfpm.conf" >> /etc/php/${PHPVERSION}/fpm/pool.d/www.conf ;\
        echo "include=/var/roundcube/config/phpfpm.conf.override" >> /etc/php/${PHPVERSION}/fpm/pool.d/www.conf ;\
        echo "Include /var/roundcube/config/httpd.conf" > /etc/apache2.orig/sites-enabled/000-default.conf ;\
        mv /etc/php /etc/php.orig && mkdir /etc/php ;\
        mkdir -p /var/roundcube/config.orig ;\
        cp /opt/roundcube/config/defaults.inc.php /var/roundcube/config.orig ;\
        touch /var/roundcube/config.orig/phpfpm.conf.override ;\
        cp -rp /opt/roundcube/plugins /opt/roundcube/plugins.orig ;\
	apt-get -y purge curl git unzip mailutils nullmailer; \
	apt-get -y autoremove && apt-get -y clean && apt-get -y autoclean; \
        rm -rf /var/lib/apt/lists/* ;\
	rm -rf ${INSTALLDIR}/installer ${INSTALLDIR}/.ci ${INSTALLDIR}/.git* ${INSTALLDIR}/.travis.yml /root/.c* ;\
        chown -R www-data:www-data ${INSTALLDIR}/logs; \
        chown -R www-data:www-data ${INSTALLDIR}/temp ;\
        chmod +x /wait-for-it.sh; \
        chmod +x /bootstrap.sh

COPY httpd.conf /var/roundcube/config.orig
COPY phpfpm.conf /var/roundcube/config.orig

ENTRYPOINT ["/bootstrap.sh"]

# expose these volumes
VOLUME /var/roundcube/config
VOLUME /var/roundcube/db
VOLUME /opt/roundcube
VOLUME /tmp/roundcube-temp

