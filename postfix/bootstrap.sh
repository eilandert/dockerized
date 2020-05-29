#!/bin/sh

        echo "[POSTFIX] This docker image can be found on https://hub.docker.com/u/eilandert and https://github.com/eilandert/dockerized"

	FIRSTRUN="/etc/postfix/main.cf"
        if [ ! -f ${FIRSTRUN} ]; then
          echo "[POSTFIX] main.cf not found, populating default configs to /etc/postfix"
	  mkdir -p /etc/postfix \
          && cp -r /etc/postfix.orig/* /etc/postfix/
        fi

        if [ -n "SYSLOG_HOST" ]; then
          echo "destination dst { syslog(\"${SYSLOG_HOST}\" transport(\"udp\")); };" > /etc/syslog-ng/conf.d/remote.conf
          echo "log { source(s_sys); destination(dst); };" >> /etc/syslog-ng/conf.d/remote.conf
          syslog-ng
          postconf -# maillog_file
          echo "[POSTFIX] Output is set to remote syslog at ${SYSLOG_HOST}"
        else
          postconf maillog_file=/dev/stdout
        fi

        chmod 777 /dev/stdout

        exec postfix start-fg
