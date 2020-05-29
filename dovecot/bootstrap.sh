#!/bin/sh

        echo "[DOVECOT] This docker image can be found on https://hub.docker.com/u/eilandert and https://github.com/eilandert/dockerized"

	FIRSTRUN="/etc/dovecot/dovecot.conf"
	if [ ! -f ${FIRSTRUN} ]; then
	  echo "[DOVECOT] no configs found, copying..."
	  mkdir -p /etc/dovecot && cp -r /etc/dovecot.orig/* /etc/dovecot/
	fi

        if [ -n "SYSLOG_HOST" ]; then
          sed -i s/"\log_path\ \=\ syslog"/"#log_path\ \=\ \/dev\/stdout"/ /etc/dovecot/conf.d/10-logging.conf
          syslogd -R ${SYSLOG_HOST}
          echo "[DOVECOT] Output is set to remote syslog at ${SYSLOG_HOST}"
        else
          sed -i s/"\#log_path\ \=\ syslog"/"log_path\ \=\ \/dev\/stdout"/ /etc/dovecot/conf.d/10-logging.conf
        fi

	chmod 777 /dev/stdout

	exec /usr/sbin/dovecot -F
