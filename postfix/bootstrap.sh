#!/bin/sh

        echo "[POSTFIX] This docker image can be found on https://hub.docker.com/u/eilandert and https://github.com/eilandert/dockerized"

        #set nameserver if variable is set
        if [ -n "${NAMESERVER}" ]; then
                echo "nameserver ${NAMESERVER}" > /etc/resolv.conf
                echo "[POSTFIX] wait for nameserver to be up with timeout of 60 secs"
                ping -c1 -W60 ${NAMESERVER}
        fi

	FIRSTRUN="/etc/postfix/main.cf"
        if [ ! -f ${FIRSTRUN} ]; then
          echo "[POSTFIX] main.cf not found, populating default configs to /etc/postfix"
	  mkdir -p /etc/postfix \
          && cp -r /etc/postfix.orig/* /etc/postfix/
        fi

        postconf maillog_file=/dev/stdout
        chmod 777 /dev/stdout

        exec postfix start-fg
