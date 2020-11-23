#!/bin/bash

echo "[ROUNDCUBE] This docker image can be found on https://hub.docker.com/u/eilandert or https://github.com/eilandert/dockerized"

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
    #    echo "[ROUNDCUBE] apache: no configs found, populating default configs to /etc/apache2"
    cp -r /etc/apache2.orig/* /etc/apache2/
fi

FIRSTRUN="/etc/php/${PHPVERSION}/fpm/php-fpm.conf"
if [ ! -f ${FIRSTRUN} ]; then
    #    echo "[ROUNDCUBE] php: no configs found, populating default configs to /etc/php/${PHPVERSION}"
    mkdir -p /etc/php/${PHPVERSION}
    cp -r /etc/php.orig/${PHPVERSION}/* /etc/php/${PHPVERSION}
fi

service php${PHPVERSION}-fpm restart 1>/dev/null 2>&1

cd ${INSTALLDIR}

if [ -f /run/secrets/roundcube_db_user ]; then
    ROUNDCUBEMAIL_DB_USER=`cat /run/secrets/roundcube_db_user`
fi
if [ -f /run/secrets/roundcube_db_password ]; then
    ROUNDCUBEMAIL_DB_PASSWORD=`cat /run/secrets/roundcube_db_password`
fi

if [ ! -z "${!POSTGRES_ENV_POSTGRES_*}" ] || [ "$ROUNDCUBEMAIL_DB_TYPE" == "pgsql" ]; then
    : "${ROUNDCUBEMAIL_DB_TYPE:=pgsql}"
    : "${ROUNDCUBEMAIL_DB_HOST:=postgres}"
    : "${ROUNDCUBEMAIL_DB_PORT:=5432}"
    : "${ROUNDCUBEMAIL_DB_USER:=${POSTGRES_ENV_POSTGRES_USER}}"
    : "${ROUNDCUBEMAIL_DB_PASSWORD:=${POSTGRES_ENV_POSTGRES_PASSWORD}}"
    : "${ROUNDCUBEMAIL_DB_NAME:=${POSTGRES_ENV_POSTGRES_DB:-roundcubemail}}"
    : "${ROUNDCUBEMAIL_DSNW:=${ROUNDCUBEMAIL_DB_TYPE}://${ROUNDCUBEMAIL_DB_USER}:${ROUNDCUBEMAIL_DB_PASSWORD}@${ROUNDCUBEMAIL_DB_HOST}:${ROUNDCUBEMAIL_DB_PORT}/${ROUNDCUBEMAIL_DB_NAME}}"

    /wait-for-it.sh -q ${ROUNDCUBEMAIL_DB_HOST}:${ROUNDCUBEMAIL_DB_PORT} -t 30

elif [ ! -z "${!MYSQL_ENV_MYSQL_*}" ] || [ "$ROUNDCUBEMAIL_DB_TYPE" == "mysql" ]; then
    : "${ROUNDCUBEMAIL_DB_TYPE:=mysql}"
    : "${ROUNDCUBEMAIL_DB_HOST:=mysql}"
    : "${ROUNDCUBEMAIL_DB_PORT:=3306}"
    : "${ROUNDCUBEMAIL_DB_USER:=${MYSQL_ENV_MYSQL_USER:-root}}"
    if [ "$ROUNDCUBEMAIL_DB_USER" = 'root' ]; then
        : "${ROUNDCUBEMAIL_DB_PASSWORD:=${MYSQL_ENV_MYSQL_ROOT_PASSWORD}}"
    else
        : "${ROUNDCUBEMAIL_DB_PASSWORD:=${MYSQL_ENV_MYSQL_PASSWORD}}"
    fi
    : "${ROUNDCUBEMAIL_DB_NAME:=${MYSQL_ENV_MYSQL_DATABASE:-roundcubemail}}"
    : "${ROUNDCUBEMAIL_DSNW:=${ROUNDCUBEMAIL_DB_TYPE}://${ROUNDCUBEMAIL_DB_USER}:${ROUNDCUBEMAIL_DB_PASSWORD}@${ROUNDCUBEMAIL_DB_HOST}:${ROUNDCUBEMAIL_DB_PORT}/${ROUNDCUBEMAIL_DB_NAME}}"

    /wait-for-it.sh -q ${ROUNDCUBEMAIL_DB_HOST}:${ROUNDCUBEMAIL_DB_PORT} -t 30

else
    # use local SQLite DB in /var/roundcube/db
    : "${ROUNDCUBEMAIL_DB_TYPE:=sqlite}"
    : "${ROUNDCUBEMAIL_DB_DIR:=/var/roundcube/db}"
    : "${ROUNDCUBEMAIL_DB_NAME:=sqlite}"
    : "${ROUNDCUBEMAIL_DSNW:=${ROUNDCUBEMAIL_DB_TYPE}:///$ROUNDCUBEMAIL_DB_DIR/${ROUNDCUBEMAIL_DB_NAME}.db?mode=0646}"

    mkdir -p $ROUNDCUBEMAIL_DB_DIR
    chown www-data:www-data $ROUNDCUBEMAIL_DB_DIR
fi

: "${ROUNDCUBEMAIL_DEFAULT_HOST:=localhost}"
: "${ROUNDCUBEMAIL_DEFAULT_PORT:=143}"
: "${ROUNDCUBEMAIL_SMTP_SERVER:=localhost}"
: "${ROUNDCUBEMAIL_SMTP_PORT:=587}"
: "${ROUNDCUBEMAIL_PLUGINS:=archive,zipdownload}"
: "${ROUNDCUBEMAIL_SKIN:=larry}"
: "${ROUNDCUBEMAIL_TEMP_DIR:=/tmp/roundcube-temp}"

ROUNDCUBEMAIL_PLUGINS_PHP=`echo "${ROUNDCUBEMAIL_PLUGINS}" | sed -E "s/[, ]+/', '/g"`
ROUNDCUBEMAIL_DES_KEY=`test -f /run/secrets/roundcube_des_key && cat /run/secrets/roundcube_des_key || head /dev/urandom | base64 | head -c 24`

#    echo "Write config to $PWD/config/config.inc.php"
echo "<?php
    \$config = array();
    \$config['db_dsnw'] = '${ROUNDCUBEMAIL_DSNW}';
    \$config['db_dsnr'] = '${ROUNDCUBEMAIL_DSNR}';
    \$config['default_host'] = '${ROUNDCUBEMAIL_DEFAULT_HOST}';
    \$config['default_port'] = '${ROUNDCUBEMAIL_DEFAULT_PORT}';
    \$config['smtp_server'] = '${ROUNDCUBEMAIL_SMTP_SERVER}';
    \$config['smtp_port'] = '${ROUNDCUBEMAIL_SMTP_PORT}';
    \$config['des_key'] = '${ROUNDCUBEMAIL_DES_KEY}';
    \$config['temp_dir'] = '${ROUNDCUBEMAIL_TEMP_DIR}';
    \$config['plugins'] = ['${ROUNDCUBEMAIL_PLUGINS_PHP}'];
    \$config['zipdownload_selection'] = true;
    \$config['log_driver'] = 'stdout';
    \$config['skin'] = '${ROUNDCUBEMAIL_SKIN}';
" > ${INSTALLDIR}/config/config.inc.php

if [ ! -f /var/roundcube/config/config.inc.php ]; then
    echo "# When mounted, you can make persistent additions to the roundcube config in this file" > /var/roundcube/config/config.inc.php
fi

for fn in `ls /var/roundcube/config/*.php 2>/dev/null || true`; do
    echo "include('$fn');" >> config/config.inc.php
done

# initialize or update DB
bin/initdb.sh --dir=$PWD/SQL --create 1>/dev/null 2>&1 || bin/updatedb.sh --dir=$PWD/SQL --package=roundcube || echo "Failed to initialize database. Please run $PWD/bin/initdb.sh and $PWD/bin/updatedb.sh manually."

cp -rp ${INSTALLDIR}/plugins.orig/* ${INSTALLDIR}/plugins/

if [ ! -z "${ROUNDCUBEMAIL_TEMP_DIR}" ]; then
    mkdir -p ${ROUNDCUBEMAIL_TEMP_DIR} && chown www-data ${ROUNDCUBEMAIL_TEMP_DIR}
fi

if [ ! -z "${ROUNDCUBEMAIL_UPLOAD_MAX_FILESIZE}" ]; then
    echo "php_admin_value[upload_max_filesize]=${ROUNDCUBEMAIL_UPLOAD_MAX_FILESIZE}" > /var/roundcube/config/phpfpm.conf.override
    echo "php_admin_value[post_max_size]=${ROUNDCUBEMAIL_UPLOAD_MAX_FILESIZE}" >> /var/roundcube/config/phpfpm.conf.override
fi

: "${ROUNDCUBEMAIL_LOCALE:=en_US.UTF-8 UTF-8}"

if [ ! -z "${ROUNDCUBEMAIL_LOCALE}" ]; then
    echo "${ROUNDCUBEMAIL_LOCALE}" > /etc/locale.gen
    /usr/sbin/locale-gen 1>/dev/null 2>&1
fi

if [ -n "${CLEAN_USERS_DAYS}" ]; then
    echo "Clean userdatabase at ${CLEAN_USERS_DAYS} days"
    ${INSTALLDIR}/bin/deluser.sh --age=${CLEAN_USERS_DAYS}
fi

# Trigger garbage collecting routines manually
${INSTALLDIR}/bin/gc.sh

cp -rp /var/roundcube/config.orig/defaults.inc.php /var/roundcube/config/defaults.php.orig

rm -f ${INSTALLDIR}/index.html

if [ ! -f /var/roundcube/config/phpfpm.conf ]; then
    cp -rp /var/roundcube/config.orig/phpfpm.conf /var/roundcube/config/phpfpm.conf
fi

if [ ! -f /var/roundcube/config/httpd.conf ]; then
    cp -rp /var/roundcube/config.orig/httpd.conf /var/roundcube/config/httpd.conf
fi

if [ -f /etc/apache2/mods-enabled/ssl.load ]; then
    while [ 1 ]; do sleep 1d; apachectl graceful; done &
fi

if [ -f /run/apache2/apache2.pid ]; then
    rm /run/apache2/apache2.pid
fi

exec /usr/sbin/apache2ctl -DFOREGROUND

