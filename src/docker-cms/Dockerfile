FROM    eilandert/debian-base:stable
LABEL org.opencontainers.image.authors="eilandert"
LABEL org.opencontainers.image.source="https://github.com/eilandert/dockerized"

LABEL   maintainer="Thijs Eilander <eilander@myguard.nl>"
ENV     DEBIAN_FRONTEND="noninteractive"
ENV     TZ=Europe/Amsterdam

COPY    bootstrap.sh /bootstrap.sh

RUN set -ex ;\
    echo "deb [trusted=yes] http://deb.myguard.nl:8888 ${DIST} main" > /etc/apt/sources.list.d/deb.myguard.nl.list ;\
    apt-get -y update ;\
    apt-get install -y nullmailer mailutils ;\
    rm -rf /var/spool/nullmailer/trigger ;\
    apt-get install -y nano less imagemagick mariadb-client wget curl sudo mc libvips42 php-vips \
    unzip zip git rsync cron jq pv openssh-client ;\
    apt-get install -y --no-install-recommends \
    php8.5 \
    php8.5-apcu \
    php8.5-bcmath \
    php8.5-cli \
    php8.5-curl \
    php8.5-dom \
    php8.5-exif \
    php8.5-gd \
    php8.5-gmp \
    php8.5-igbinary \
    php8.5-imagick \
    php8.5-imap \
    php8.5-intl \
    php8.5-ldap \
    php8.5-memcache \
    php8.5-mbstring \
    php8.5-mysql \
    php8.5-pspell \
    php8.5-pgsql \
    php8.5-readline \
    php8.5-redis \
    php8.5-soap \
    php8.5-sqlite3 \
    php8.5-tidy \
    php8.5-xml \
    php8.5-zip ;\
    apt-get -y autoremove && apt-get -y autoclean ;\
    rm -rf /var/lib/apt/lists/* /var/cache/apt

RUN set -ex ;\
    cd /tmp ;\
    php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');" ;\
    cat /tmp/composer-setup.php | php -- --filename=composer --install-dir=/usr/bin ;\
    php -r "unlink('composer-setup.php');" ;\
    php -r "copy('https://raw.githubusercontent.com/wp-cli/wp-cli/v2.9.0/utils/wp-completion.bash', '/usr/lib/wp-completion.bash');" ;\
    php -r "copy('https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar', '/usr/bin/wp');" ;\
    chmod +x /usr/bin/wp ;\
    echo "alias wp='sudo -u www-data -i -- wp --path=\$(pwd)'" >> /root/.bashrc ;\
    echo "source /usr/lib/wp-completion.bash" >> /root/.bashrc ;\
    mkdir /var/www ;\
    chsh www-data -s /bin/bash

RUN set -ex ;\
    rm -rf /var/lib/apt/lists/* /tmp/* ;\
    rm -rf /etc/php/5.6 /usr/lib/php/20131226 ;\
    rm -rf /etc/php/7.0 /usr/lib/php/20151012 ;\
    rm -rf /etc/php/7.1 /usr/lib/php/20160303 ;\
    rm -rf /etc/php/7.2 /usr/lib/php/20170718 ;\
    rm -rf /etc/php/7.3 /usr/lib/php/20180731 ;\
    rm -rf /etc/php/7.4 /usr/lib/php/20190902 ;\
    rm -rf /etc/php/8.0 /usr/lib/php/20200930 ;\
    rm -rf /etc/php/8.1 /usr/lib/php/20210902 ;\
    rm -rf /etc/php/8.2 /usr/lib/php/20220829 ;\
    mv /etc/php /etc/php.orig && mkdir -p /etc/php ;\
    mv /etc/nullmailer /etc/nullmailer.orig && mkdir -p /etc/nullmailer ;\
    echo "alias ls='ls --color=auto'" >> /root/.bashrc ;\
    echo "alias grep='grep --color=auto'" >> /root/.bashrc ;\
    chmod 755 /bootstrap.sh ;\
    chmod 755 /usr/bin/sudo

CMD     ["/bootstrap.sh"]
