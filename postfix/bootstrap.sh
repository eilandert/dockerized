#!/bin/sh

        echo "[BOOTSTRAP] This docker image can be found on"
        echo "[BOOTSTRAP] https://hub.docker.com/u/eilandert or https://github.com/eilandert/dockerized"
        echo "[BOOTSTRAP]"
        echo "[BOOTSTRAP] optional variables for this container:"
        echo "[BOOTSTRAP] NAMESERVER"

        #set nameserver if variable is set
        if [ -n "${NAMESERVER}" ]; then
                echo "nameserver ${NAMESERVER}" > /etc/resolv.conf
                echo "[BOOTSTRAP] wait for nameserver to be up with timeout of 60 secs"
                ping -c1 -W60 ${NAMESERVER}
        fi

	FIRSTRUN="/etc/postfix/main.cf"
        if [ ! -f ${FIRSTRUN} ]; then
          echo "[BOOTSTRAP] main.cf not found, populating default configs to /etc/postfix"
	  mkdir -p /etc/postfix \
          && cp -r /etc/postfix.orig/* /etc/postfix/
        fi

        postconf maillog_file=/dev/stdout
        chmod 777 /dev/stdout

        exec postfix start-fg
