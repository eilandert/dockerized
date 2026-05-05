#!/bin/bash

. /etc/os-release
VERSION=$(valkey-server -v)
TEXT="Valkey image from https://hub.docker.com/u/eilandert with packages from https://deb.myguard.nl"

if [ -n "${TZ}" ]; then
    rm -f /etc/timezone /etc/localtime
    echo "${TZ}" > /etc/timezone
    ln -s /usr/share/zoneinfo/${TZ} /etc/localtime
fi

if [ -n "${SYSLOG_HOST}" ]; then
    mkdir -p /etc/syslog-ng/conf.d
    echo "destination dst { syslog(\"${SYSLOG_HOST}\" transport(\"udp\")); };" > /etc/syslog-ng/conf.d/remote.conf
    echo "log { source(s_sys); destination(dst); };" >> /etc/syslog-ng/conf.d/remote.conf
    sed -i s/"^# syslog-enabled no"/"syslog-enabled yes/" /etc/valkey/valkey.conf
    syslog-ng --no-caps
    logger "${TEXT}" && logger "Running on ${PRETTY_NAME}" && logger "Starting ${VERSION}...."
    echo "[VALKEY] Output is set to remote syslog at ${SYSLOG_HOST}"
else
    sed -i s/"^syslog-enabled yes/# syslog-enabled no"/ /etc/valkey/valkey.conf
    rm -f /etc/syslog-ng/conf.d/remote.conf
fi

FIRSTRUN="/etc/valkey/valkey.conf"
if [ ! -f ${FIRSTRUN} ]; then
    echo "[VALKEY] valkey.conf not found, populating default configs to /etc/valkey"
    mkdir -p /etc/valkey/
    cp -r /etc/valkey.orig/* /etc/valkey/
fi

# disable Valkey protected mode and bind as it is unnecessary in context of Docker
# Also, run in foreground so docker exits when valkey exits
sed -i s/"^bind\ "/#bind\ / /etc/valkey/valkey.conf ;\
sed -i s/"protected-mode yes"/"protected-mode no"/ /etc/valkey/valkey.conf ;\
sed -i s/"daemonize yes"/"daemonize no"/ /etc/valkey/valkey.conf ;\

echo "${TEXT}" && echo "Running on ${PRETTY_NAME}" && echo "Starting ${VERSION}...."

exec /usr/bin/valkey-server /etc/valkey/valkey.conf
