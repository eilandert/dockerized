#!/bin/sh

chmod 777 /dev/stdout

echo "[NGINX] This docker image can be found on https://hub.docker.com/u/eilandert or https://github.com/eilandert/dockerized"
echo "[NGINX] The NGINX packages (and detailed description of this NGINX stack can be found on https://deb.paranoid.nl"

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


#check if PHP is installed, else skip the whole block
if [ -n "${PHPVERSION}" ]; then

    startphp()
    {
        # set PHPVERSION for MULTI mode
        PHPVERSION="$1"
        FIRSTRUN="/etc/php/${PHPVERSION}/fpm/php-fpm.conf"
        if [ ! -f ${FIRSTRUN} ]; then
            echo "[NGINX] no configs found, populating default configs to /etc/php/${PHPVERSION}"
            mkdir -p /etc/php/${PHPVERSION}
            cp -r /etc/php.orig/${PHPVERSION}/* /etc/php/${PHPVERSION}
        fi
        php-fpm${PHPVERSION} -v
        php-fpm${PHPVERSION} -t
        service php${PHPVERSION}-fpm restart 1>/dev/null 2>&1
    }

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

    COMPOSERPATH="/usr/bin/composer"
    if [ ! -f ${COMPOSERPATH} ]; then
        cd /tmp
        php composer-setup.php --quiet
        mv composer.phar ${COMPOSERPATH}
    fi

    if [ "${PHPVERSION}" = "MULTI" ] && [ ! "${PHP56}" = "YES" ] && [ ! "${PHP72}" = "YES" ] && [ ! "${PHP74}" = "YES" ] && [ ! "${PHP80}" = "YES" ] && [ ! "${PHP81}" = "YES" ]; then
        echo "[NGINX] You downloaded the MULTI-PHP edition of the docker"
        echo "[NGINX] There is no PHP56 PHP72 PHP74 PHP80 PHP81 environment variable specified"
        echo "[NGINX] exiting...."
        sleep 10
        exit
    fi

    if [ "${MODE}" = "FPM" ] && [ ! "${MODE}" = "MULTI" ]; then
        startphp "${PHPVERSION}"
    fi

    if [ "${MODE}" = "MULTI" ] && [ "${PHP56}" = "YES" ]; then
        startphp "5.6"
    fi

    if [ "${MODE}" = "MULTI" ] && [ "${PHP72}" = "YES" ]; then
        startphp "7.2"
    fi

    if [ "${MODE}" = "MULTI" ] && [ "${PHP74}" = "YES" ]; then
        startphp "7.4"
    fi

    if [ "${MODE}" = "MULTI" ] && [ "${PHP80}" = "YES" ]; then
        startphp "8.0"
    fi

    if [ "${MODE}" = "MULTI" ] && [ "${PHP81}" = "YES" ]; then
        startphp "8.1"
    fi


fi

#download new pagespeed libraries on docker startup
chmod +x /etc/nginx/scripts/pagespeed_libraries_generator.sh 1>/dev/null 2>&1
/etc/nginx/scripts/pagespeed_libraries_generator.sh > /etc/nginx/snippets/pagespeed_libraries.conf 2>/dev/null

nginx -V 2>&1 | grep -v configure
nginx -t

#echo "Automaticly reloading configs everyday to pick up new ssl certificates"
while [ 1 ]; do sleep 1d; nginx -s reload; done &

exec nginx -g 'daemon off;'
