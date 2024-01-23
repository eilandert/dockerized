FROM    eilandert/debian-base:stable
LABEL   maintainer="Thijs Eilander <eilander@myguard.nl>"
ENV     DEBIAN_FRONTEND="noninteractive"
ENV     TZ=Europe/Amsterdam

COPY    bootstrap.sh /bootstrap.sh

RUN set -ex ;\
    echo "deb [trusted=yes] http://packages.sury.org/php/ ${DIST} main" > /etc/apt/sources.list.d/ondrej-ppa.list ;\
    apt-get -y update 

RUN apt-get install -y nullmailer mailutils ;\
    rm -rf /var/spool/nullmailer/trigger

RUN apt-get install -y nano less imagemagick mariadb-client wget curl sudo mc

RUN set -x ;\
    apt-get update ;\
    apt-get install -m -y --no-install-recommends \
    php8.3 \
    php8.3-apcu \
    php8.3-bcmath \
    php8.3-cli \
    php8.3-curl \
    php8.3-dom \
    php8.3-exif \
    php8.3-gd \
    php8.3-gmp \
    php8.3-igbinary \
    php8.3-imagick \
    php8.3-imap \
    php8.3-intl \
    php8.3-ldap \
    php8.3-memcache \
    php8.3-mbstring \
    php8.3-mysql \
    php8.3-opcache \
    php8.3-pspell \
    php8.3-pgsql \
    php8.3-readline \
    php8.3-redis \
    php8.3-soap \
    php8.3-sqlite3 \
    php8.3-tidy \
    php8.3-xml \
    php8.3-zip ;\
    apt-get -y autoremove && apt-get -y autoclean ;\
    rm -rf /var/lib/apt/lists/*

RUN	set -ex ;\
    cd /tmp ;\
    php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');" ;\
    cat /tmp/composer-setup.php | php -- --filename=composer --install-dir=/usr/bin ;\
    php -r "unlink('composer-setup.php');" 

RUN	set -ex ;\
    php -r "copy('https://raw.githubusercontent.com/wp-cli/wp-cli/v2.9.0/utils/wp-completion.bash', '/usr/lib/wp-completion.bash');" ;\
    php -r "copy('https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar', '/usr/bin/wp');"  ;\
    chmod +x /usr/bin/wp ;\
    echo "alias wp='sudo -u www-data -i -- wp --path=$(pwd)'" >> /root/.bashrc ;\
    echo "source /usr/lib/wp-completion.bash"  >> /root/.bashrc ;\
    mkdir /var/www ;\ 
    chsh www-data -s /bin/bash

RUN	set -ex ;\
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
    #rm -rf /etc/php/8.3 /usr/lib/php/20230831 ;\
    mv /etc/php /etc/php.orig && mkdir -p /etc/php ;\
    mv /etc/nullmailer /etc/nullmailer.orig && mkdir -p /etc/nullmailer ;\
    echo "alias ls='ls --color=auto'" >> /root/.bashrc ;\
    echo "alias grep='grep --color=auto'"  >> /root/.bashrc ;\
    chmod 755 /bootstrap.sh ;\
    chmod 755 /usr/bin/sudo 

CMD     ["/bootstrap.sh"]

