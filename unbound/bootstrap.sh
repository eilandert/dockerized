#!/bin/sh
set -eu

        echo "nameserver ${NAMESERVER}" > /etc/resolv.conf

	UNBOUNDCONF="/config/unbound.conf"
	if [ ! -f ${UNBOUNDCONF} ]; then
		echo "[bootstrap] no config found, assuming first run."
		mkdir -p /config
		cp -r config.orig/* /config/
	fi

exec /usr/sbin/unbound -c /config/unbound.conf
