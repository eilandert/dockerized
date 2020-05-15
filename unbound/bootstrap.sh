#!/bin/sh

        echo "[BOOTSTRAP] This docker image can be found on"
        echo "[BOOTSTRAP] https://hub.docker.com/u/eilandert or https://github.com/eilandert/dockerized"
        echo "[BOOTSTRAP]"
        echo "[BOOTSTRAP] optional variables for this container:"
        echo "[BOOTSTRAP] NAMESERVER"

        #set nameserver if variable is set
        if [ -n "${NAMESERVER}" ]; then
                echo "$nameserver ${NAMESERVER}" > /etc/resolv.conf
                echo "[BOOTSTRAP] wait for nameserver to be up with timeout of 60 secs"
                ping -c1 -W60 ${NAMESERVER}
        fi

	UNBOUNDCONF="/config/unbound.conf"
	if [ ! -f ${UNBOUNDCONF} ]; then
                echo "[BOOTSTRAP] unbound.conf not found, populating default configs to /config"
		mkdir -p /config
		cp -r config.orig/* /config/
	fi

        exec /usr/sbin/unbound -c /config/unbound.conf
