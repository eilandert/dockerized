#!/bin/sh

UNBOUNDCONF="/config/unbound.conf"
if [ ! -f ${UNBOUNDCONF} ]; then
    echo "[bootstrap] no config found, assuming first run."
    mkdir -p /config
    cp -r config.orig/* /config/
fi

   echo "nameserver ${NAMESERVER}" > /etc/resolv.conf

exec /usr/sbin/unbound -c /config/unbound.conf
