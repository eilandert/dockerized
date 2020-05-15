#!/bin/sh

	if [ -n "${NAMESERVER}" ]; then
		echo "nameserver ${NAMESERVER}" > /etc/resolv.conf
	fi


    FIRSTRUN="/etc/dovecot/dovecot.conf"
    if [ ! -f ${FIRSTRUN} ]; then
      echo "[bootstrap] no configs found, copying..."
      mkdir -p /etc/dovecot \
      && cp -r /etc/dovecot.orig/* /etc/dovecot/
      sed -i s/"\#log_path\ \=\ syslog"/"log_path\ \=\ \/dev\/stdout"/ /etc/dovecot/conf.d/10-logging.conf
    fi

    chmod 777 /dev/stdout


exec /usr/sbin/dovecot -F
