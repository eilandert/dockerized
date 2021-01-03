#!/bin/sh

echo "[DOVECOT] This docker image can be found on https://hub.docker.com/u/eilandert and https://github.com/eilandert/dockerized"

FIRSTRUN="/etc/dovecot/dovecot.conf"
if [ ! -f ${FIRSTRUN} ]; then
    echo "[DOVECOT] no configs found, copying default configs to /etc/dovecot"
    mkdir -p /etc/dovecot && cp -r /etc/dovecot.orig/* /etc/dovecot/
fi

if [ -n "${TZ}" ]; then
    rm -f /etc/timezone /etc/localtime
    echo "${TZ}" > /etc/timezone
    ln -s /usr/share/zoneinfo/${TZ} /etc/localtime
fi

if [ -n "${SYSLOG_HOST}" ]; then
    mkdir -p /etc/syslog-ng/conf.d
    echo "destination dst { syslog(\"${SYSLOG_HOST}\" transport(\"udp\")); };" > /etc/syslog-ng/conf.d/remote.conf
    echo "log { source(s_sys); destination(dst); };" >> /etc/syslog-ng/conf.d/remote.conf
    syslog-ng --no-caps
    echo "[DOVECOT] Output is set to remote syslog at ${SYSLOG_HOST}"
else
    rm -f /etc/syslog-ng/conf.d/remote.conf
fi

#if [ -n "${DB_DRIVER}" ]; then
#    sed -i s/"driver = .*"/"driver = ${DB_DRIVER}"/ /etc/dovecot/dovecot-sql.conf.ext
#    sed -i s/"connect = host=localhost user=vimbadmin password=password dbname=vimbadmin"/"connect = host=${DB_HOST} user=${DB_USERNAME} password=${DB_PASSWORD} dbname=${DB_DATABASE}"/ /etc/dovecot/dovecot-sql.conf.ext
#fi

if [ -n "${USE_VIMBADMIN}" ]; then
    cp -rp /opt/scripts/vimbadmin.orig /opt/scripts/vimbadmin
    sed -i s/"my \$driver .*"/"my \$driver   = \"${DB_DRIVER}\";"/ /opt/scripts/vimbadmin/*
    sed -i s/"my \$database .*"/"my \$database = \"${DB_DATABASE}\";"/ /opt/scripts/vimbadmin/*
    sed -i s/"my \$host .*"/"my \$host = \"${DB_HOST}\";"/ /opt/scripts/vimbadmin/*
    sed -i s/"my \$port .*"/"my \$port = \"${DB_PORT}\";"/ /opt/scripts/vimbadmin/*
    sed -i s/"my \$username .*"/"my \$username = \"${DB_USERNAME}\";"/ /opt/scripts/vimbadmin/*
    sed -i s/"my \$password .*"/"my \$password = \"${DB_PASSWORD}\";"/ /opt/scripts/vimbadmin/*
    /opt/scripts/vimbadmin/update_mailbox_size.pl &
fi

#echo "Automaticly reloading configs everyday to pick up new ssl certificates"
while [ 1 ]; do
    sleep 1d;
    dovecot reload;
    if [ -n "${USE_VIMBADMIN}" ]; then
        /opt/scripts/vimbadmin/update_mailbox_size.pl 
    fi
done &

chmod 777 /dev/stdout

exec /usr/sbin/dovecot -F

