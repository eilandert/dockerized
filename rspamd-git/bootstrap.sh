#!/bin/sh

        echo "[RSPAMD] This docker image can be found on https://hub.docker.com/u/eilandert and https://github.com/eilandert/dockerized"

        FIRSTRUN="/usr/local/etc/rspamd/rspamd.conf"
        if [ ! -f ${FIRSTRUN} ]; then
          echo "[RSPAMD] no configs found, populating default configs to /usr/local/etc/rspamd"
          mkdir -p /usr/local/etc/rspamd
          cp -r /usr/local/etc/rspamd.orig/* /usr/local/etc/rspamd/

	  mkdir -p /var/log/rspamd
	  mkdir -p /var/lib/rspamd
	  mkdir -p /var/run/rspamd

          chown _rspamd:_rspamd -R /var/log/rspamd
          chown _rspamd:_rspamd -R /var/lib/rspamd
          chown _rspamd:_rspamd -R /var/run/rspamd

	fi

	if [ -n "${TZ}" ]; then
	  echo "${TZ}" > /etc/timezone
	fi

	mkdir -p /usr/local/etc/rspamd/override.d
        if [ -n "${SYSLOG_HOST}" ]; then
	  mkdir -p /etc/syslog-ng/conf.d
          echo "destination dst { syslog(\"${SYSLOG_HOST}\" transport(\"udp\")); };" > /etc/syslog-ng/conf.d/remote.conf
          echo "log { source(s_sys); destination(dst); };" >> /etc/syslog-ng/conf.d/remote.conf
	  syslog-ng
          echo "type = \"syslog\";" > /usr/local/etc/rspamd/override.d/logging.inc
          echo "[RSPAMD] Output is set to remote syslog at ${SYSLOG_HOST}"
        else
          echo "type = \"console\";" > /usr/local/etc/rspamd/override.d/logging.inc
        fi

exec	/usr/local/bin/rspamd -f -u _rspamd -g _rspamd;
