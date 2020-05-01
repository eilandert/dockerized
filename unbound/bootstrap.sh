#!/bin/sh
set -eu

	if [ -z ${NAMESERVER} ]; then
	  echo "nameserver ${NAMESERVER}" > /etc/resolv.conf
	fi

	UNBOUNDCONF="/config/unbound.conf"
	if [ ! -f ${UNBOUNDCONF} ]; then
		echo "[bootstrap] no config found, assuming first run."
		mkdir -p /config
		cp -r config.orig/* /config/
	fi

exec /usr/sbin/unbound -c /config/unbound.conf
