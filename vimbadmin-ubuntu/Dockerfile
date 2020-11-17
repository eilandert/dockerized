FROM	eilandert/apache-phpfpm:7.4
LABEL	maintainer="Thijs Eilander <eilander@myguard.nl>"
ENV     DEBIAN_FRONTEND="noninteractive"

ENV	INSTALL_PATH=/opt/vimbadmin

COPY	bootstrap.sh /bootstrap.sh
COPY    dovecotpasswd.php /tmp

RUN apt-get update && apt-get -y install --no-install-recommends git unzip \
  && git clone \
     --recurse-submodules \
     --depth=1 \
     -c advice.detachedHead=false \
     -j`nproc` \
     https://github.com/opensolutions/ViMbAdmin.git \
     ${INSTALL_PATH} \
  && cd ${INSTALL_PATH} \
  && rm -rf /etc/php && cp -r /etc/php.orig /etc/php \
  && composer update \
  && composer config -g secure-http false \
  && composer install --prefer-dist --no-dev \
  && rm -rf /etc/php && mkdir -p /etc/php \
  && chown -R www-data:www-data ${INSTALL_PATH}/var \
  && cp -r ${INSTALL_PATH}/application/configs ${INSTALL_PATH}/application/configs.orig \	
  && echo "Include ${INSTALL_PATH}/application/configs/httpd.conf" > /etc/apache2.orig/sites-enabled/000-default.conf \
  && echo "php_admin_flag[opcache.enable] = 1" >> /etc/php.orig/${PHPVERSION}/fpm/pool.d/www.conf \
  && rm ${INSTALL_PATH}/application/configs.orig/application.ini.vagrant \
  && mv /tmp/dovecotpasswd.php ${INSTALL_PATH}/application/configs.orig/ \
  && chmod +x ${INSTALL_PATH}/application/configs.orig/dovecotpasswd.php \
  && apt-get -y purge git unzip mailutils nullmailer \
  && apt-get -y autoremove && apt-get -y clean && apt-get -y autoclean \
  && rm -rf /var/lib/apt/lists/*  \
  && rm -rf ${INSTALL_PATH}/.git /root/.composer /root/.cache /root/.local \
  && chmod +x /bootstrap.sh 

COPY httpd.conf ${INSTALL_PATH}/application/configs.orig/

CMD "/bootstrap.sh"

EXPOSE 80/TCP
