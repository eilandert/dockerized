#!/bin/bash

echo "[REDIS] This docker image can be found on https://hub.docker.com/u/eilandert and https://github.com/eilandert/dockerized"

if [ -n "${TZ}" ]; then
    rm -f /etc/timezone /etc/localtime
    echo "${TZ}" > /etc/timezone
    ln -s /usr/share/zoneinfo/${TZ} /etc/localtime
fi

FIRSTRUN="/etc/redis/redis.conf"
if [ ! -f ${FIRSTRUN} ]; then
    echo "[REDIS] redis.conf not found, populating default configs to /etc/redis"
    mkdir -p /etc/redis/
    cp -r /etc/redis.orig/* /etc/redis/
fi

if [ -n "${SYSLOG_HOST}" ]; then
    mkdir -p /etc/syslog-ng/conf.d
    echo "destination dst { syslog(\"${SYSLOG_HOST}\" transport(\"udp\")); };" > /etc/syslog-ng/conf.d/remote.conf
    echo "log { source(s_sys); destination(dst); };" >> /etc/syslog-ng/conf.d/remote.conf
    sed -i s/"^# syslog-enabled no"/"syslog-enabled yes/" /etc/redis/redis.conf
    syslog-ng --no-caps
    echo "[REDIS] Output is set to remote syslog at ${SYSLOG_HOST}"
else
    sed -i s/"^syslog-enabled yes/# syslog-enabled no"/ /etc/redis/redis.conf
    rm -f /etc/syslog-ng/conf.d/remote.conf
fi

exec /usr/bin/redis-server /etc/redis/redis.conf
