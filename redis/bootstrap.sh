#!/bin/bash

. /etc/os-release
VERSION=$(redis-server -v)
TEXT="Redis image from https://hub.docker.com/u/eilandert with packages from https://deb.myguard.nl"

if [ -n "${TZ}" ]; then
    rm -f /etc/timezone /etc/localtime
    echo "${TZ}" > /etc/timezone
    ln -s /usr/share/zoneinfo/${TZ} /etc/localtime
fi

if [ -n "${SYSLOG_HOST}" ]; then
    mkdir -p /etc/syslog-ng/conf.d
    echo "destination dst { syslog(\"${SYSLOG_HOST}\" transport(\"udp\")); };" > /etc/syslog-ng/conf.d/remote.conf
    echo "log { source(s_sys); destination(dst); };" >> /etc/syslog-ng/conf.d/remote.conf
    sed -i s/"^# syslog-enabled no"/"syslog-enabled yes/" /etc/redis/redis.conf
    syslog-ng --no-caps
    logger "${TEXT}" && logger "Running on ${PRETTY_NAME}" && logger "Starting ${VERSION}...."
    echo "[REDIS] Output is set to remote syslog at ${SYSLOG_HOST}"
else
    sed -i s/"^syslog-enabled yes/# syslog-enabled no"/ /etc/redis/redis.conf
    rm -f /etc/syslog-ng/conf.d/remote.conf
fi

FIRSTRUN="/etc/redis/redis.conf"
if [ ! -f ${FIRSTRUN} ]; then
    echo "[REDIS] redis.conf not found, populating default configs to /etc/redis"
    mkdir -p /etc/redis/
    cp -r /etc/redis.orig/* /etc/redis/
fi

# disable Redis protected mode and bind as it is unnecessary in context of Docker
# Also, run in foreground so docker exits when redis exits
sed -i s/"^bind\ "/#bind\ / /etc/redis/redis.conf ;\
sed -i s/"protected-mode yes"/"protected-mode no"/ /etc/redis/redis.conf ;\
sed -i s/"daemonize yes"/"daemonize no"/ /etc/redis/redis.conf ;\

echo "${TEXT}" && echo "Running on ${PRETTY_NAME}" && echo "Starting ${VERSION}...."

exec /usr/bin/redis-server /etc/redis/redis.conf
