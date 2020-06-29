FROM alpine:latest
LABEL maintainer="Thijs Eilander <eilander@myguard.nl>"

ENV INSTALL_PATH=/opt/vimbadmin

RUN  apk update && apk upgrade && apk add --no-cache git curl \
  && git clone \
              --recurse-submodules \
              --depth=1 \
              -c advice.detachedHead=false \
              -j`nproc` \
               https://github.com/opensolutions/ViMbAdmin.git \
              ${INSTALL_PATH}; 

RUN  apk add --no-cache php7-apache2 php7-phar php7-mbstring php7-mcrypt php7-json php7-pdo php-gettext \
        php7-memcached php7-pdo_mysql php7-opcache php7-tokenizer php7-simplexml php7-ctype php7-iconv php7-openssl \
        tzdata apache2 dovecot \
  && curl -sS https://getcomposer.org/installer | php7 -- --filename=composer --install-dir=/usr/local/bin \
  && cd ${INSTALL_PATH} \
  && composer config -g secure-http false \
  && composer install --prefer-dist --no-dev \
  && chown -R apache:apache ${INSTALL_PATH}/var \
  && cp -r ${INSTALL_PATH}/application/configs ${INSTALL_PATH}/application/configs.orig \	
  && echo "Include ${INSTALL_PATH}/application/configs/httpd.conf" >> /etc/apache2/httpd.conf \
  && rm ${INSTALL_PATH}/application/configs.orig/application.ini.vagrant \
  && rm -rf ${INSTALL_PATH}/.git /root/.composer /usr/local/bin/composer \
  && apk del --no-cache git libcurl curl \
  && apk del alpine-keys apk-tools \
  && rm -rf /var/cache/apk/* /lib/apk/db /usr/src/* 

COPY bootstrap.sh /bootstrap.sh
COPY httpd.conf ${INSTALL_PATH}/application/configs.orig/

RUN chmod +x /bootstrap.sh

EXPOSE 80/TCP

CMD "/bootstrap.sh"

