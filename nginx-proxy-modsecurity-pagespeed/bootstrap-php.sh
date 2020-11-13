#!/bin/sh

chmod 777 /dev/stdout

echo "[NGINX] This docker image can be found on https://hub.docker.com/u/eilandert or https://github.com/eilandert/dockerized"
echo "[NGINX] The NGINX packages can be found on https://launchpad.net/~eilander/+archive/ubuntu/nginx"

if [ -n "${TZ}" ]; then
    rm -f /etc/timezone /etc/localtime
    echo "${TZ}" > /etc/timezone
    ln -s /usr/share/zoneinfo/${TZ} /etc/localtime
fi

# If there are no configfiles, copy them
FIRSTRUN="/etc/nginx/nginx.conf"
if [ ! -f ${FIRSTRUN} ]; then
    echo "[NGINX] no configs found, populating default configs to /etc/nginx and /etc/modsecurity"
    cp -r /etc/nginx.orig/* /etc/nginx/
    cp -r /etc/modsecurity.orig/* /etc/modsecurity/
fi

FIRSTRUN="/etc/nullmailer/defaultdomain"
if [ ! -f ${FIRSTRUN} ]; then
    echo "[NGINX] no configs found, populating default configs to /etc/nullmailer"
    cp -r /etc/nullmailer.orig/* /etc/nullmailer
fi

#fix some weird issue with nullmailer
rm -f /var/spool/nullmailer/trigger
/usr/bin/mkfifo /var/spool/nullmailer/trigger
/bin/chmod 0622 /var/spool/nullmailer/trigger
/bin/chown -R mail:mail /var/spool/nullmailer/ /etc/nullmailer
runuser -u mail /usr/sbin/nullmailer-send 1>/var/log/nullmailer.log 2>&1 &

if [ ! -x /run/php ]; then
    mkdir -p /run/php
    chown www-data:www-data /run/php
    chmod 755 /run/php
fi

if [ "${PHPVERSION}" = "5.6" ]||[ "${PHPVERSION}" = "MULTI" ] ; then
    FIRSTRUN="/etc/php/5.6/fpm/php-fpm.conf"
    if [ ! -f ${FIRSTRUN} ]; then
        echo "[NGINX] no configs found, populating default configs to /etc/php/5.6"
        mkdir -p /etc/php/5.6
        cp -r /etc/php.orig/5.6/* /etc/php/5.6
    fi
    php-fpm5.6 -v
    php-fpm5.6 -t
    service php5.6-fpm restart 1>/dev/null 2>&1
fi

if [ "${PHPVERSION}" = "7.2" ]||[ "${PHPVERSION}" = "MULTI" ] ; then
    FIRSTRUN="/etc/php/7.2/fpm/php-fpm.conf"
    if [ ! -f ${FIRSTRUN} ]; then
        echo "[NGINX] no configs found, populating default configs to /etc/php/7.2"
        mkdir -p /etc/php/7.2
        cp -r /etc/php.orig/7.2/* /etc/php/7.2
    fi
    php-fpm7.2 -v
    php-fpm7.2 -t
    service php7.2-fpm restart 1>/dev/null 2>&1
fi

if [ "${PHPVERSION}" = "7.4" ]||[ "${PHPVERSION}" = "MULTI" ] ; then
    FIRSTRUN="/etc/php/7.4/fpm/php-fpm.conf"
    if [ ! -f ${FIRSTRUN} ]; then
        echo "[NGINX] no configs found, populating default configs to /etc/php/7.4"
        mkdir -p /etc/php/7.4
        cp -r /etc/php.orig/7.4/* /etc/php/7.4
    fi
    php-fpm7.4 -v 
    php-fpm7.4 -t 
    service php7.4-fpm restart 1>/dev/null 2>&1
fi

if [ "${PHPVERSION}" = "8.0" ]||[ "${PHPVERSION}" = "MULTI" ] ; then
    FIRSTRUN="/etc/php/8.0/fpm/php-fpm.conf"
    if [ ! -f ${FIRSTRUN} ]; then
        echo "[NGINX] no configs found, populating default configs to /etc/php/8.0"
        mkdir -p /etc/php/8.0
        cp -r /etc/php.orig/8.0/* /etc/php/8.0
    fi
    php-fpm8.0 -v \
    php-fpm8.0 -t
    service php8.0-fpm restart 1>/dev/null 2>&1
fi

nginx -V 2>&1 | grep -v configure
nginx -t

#echo "Automaticly reloading configs everyday to pick up new ssl certificates"
while [ 1 ]; do sleep 1d; nginx -s reload; done &

exec nginx -g 'daemon off;'
