#!/bin/sh

echo "[VIMBADMIN] This docker image can be found on https://hub.docker.com/u/eilandert and https://github.com/eilandert/dockerized"

if [ -n "${TZ}" ]; then
    rm /etc/timezone /etc/localtime
    echo "${TZ}" > /etc/timezone
    ln -s /usr/share/zoneinfo/${TZ} /etc/localtime
fi

#fix some weird issue with php-fpm
if [ ! -x /run/php ]; then
    mkdir -p /run/php
    chown www-data:www-data /run/php
    chmod 755 /run/php
fi

# If there are no configfiles, copy them
FIRSTRUN="/etc/apache2/apache2.conf"
if [ ! -f ${FIRSTRUN} ]; then
    #    echo "[VIMBADMIN] apache: no configs found, populating default configs to /etc/apache2"
    cp -r /etc/apache2.orig/* /etc/apache2/
fi

FIRSTRUN="/etc/php/${PHPVERSION}/fpm/php-fpm.conf"
if [ ! -f ${FIRSTRUN} ]; then
    #    echo "[VIMBADMIN] php: no configs found, populating default configs to /etc/php/${PHPVERSION}"
    mkdir -p /etc/php/${PHPVERSION}
    cp -r /etc/php.orig/${PHPVERSION}/* /etc/php/${PHPVERSION}
fi

FIRSTRUN="${INSTALL_PATH}/application/configs/application.ini"
if [ ! -f ${FIRSTRUN} ]; then
    echo "[VIMBADMIN] vimbadmin: application.ini not found, populating default configs to ${INSTALL_PATH}/application/configs/"
    cp -rp ${INSTALL_PATH}/application/configs.orig/* ${INSTALL_PATH}/application/configs/
    chown -R www-data:www-data ${INSTALL_PATH}/var &
else
    # 4-6-2020, change existing application.ini after upgrade to 3.2.0, removal from this file far in future.
    sed -i 's~"/../vendor/opensolutions/oss-framework/src/OSS/Resource"~"/../library/OSS/Resource"~' ${INSTALL_PATH}/application/configs/application.ini
    sed -i 's~"/../vendor/opensolutions/oss-framework/src/OSS/Smarty/functions"~"/../library/OSS/Smarty/functions"~' ${INSTALL_PATH}/application/configs/application.ini
    # 17-11-2020 remove loadmodule in the sitesnippet (migrating from alpine to ubuntu)
    sed -i '/^LoadModule/d' /etc/apache2/sites-enabled/000-default.conf
fi

service php${PHPVERSION}-fpm restart 1>/dev/null 2>&1

if [ -f /etc/apache2/mods-enabled/ssl.load ]; then
    while [ 1 ]; do sleep 1d; apachectl graceful; done &
fi

if [ -f /run/apache2/apache2.pid ]; then
    rm /run/apache2/apache2.pid
fi

exec /usr/sbin/apache2ctl -DFOREGROUND
