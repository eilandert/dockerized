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

	FIRSTRUN="/etc/dovecot/dovecot.conf"
	if [ ! -f ${FIRSTRUN} ]; then
	  echo "[bootstrap] no configs found, copying..."
	  mkdir -p /etc/dovecot && cp -r /etc/dovecot.orig/* /etc/dovecot/
	  sed -i s/"\#log_path\ \=\ syslog"/"log_path\ \=\ \/dev\/stdout"/ /etc/dovecot/conf.d/10-logging.conf
	fi

	chmod 777 /dev/stdout

	exec /usr/sbin/dovecot -F
