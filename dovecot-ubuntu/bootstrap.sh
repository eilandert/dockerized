#!/bin/sh

echo "[DOVECOT] This docker image can be found on https://hub.docker.com/u/eilandert and https://github.com/eilandert/dockerized"

FIRSTRUN="/etc/dovecot/dovecot.conf"
if [ ! -f ${FIRSTRUN} ]; then
    echo "[DOVECOT] no configs found, copying..."
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

chmod 777 /dev/stdout

exec /usr/sbin/dovecot -F
