#!/bin/sh

        echo "[RSPAMD] This docker image can be found on https://hub.docker.com/u/eilandert and https://github.com/eilandert/dockerized"

        FIRSTRUN="/etc/rspamd/rspamd.conf"
        if [ ! -f ${FIRSTRUN} ]; then
          echo "[RSPAMD] no configs found, populating default configs to /etc/rspamd"
          mkdir -p /etc/rspamd \
          && cp -r /etc/rspamd.orig/* /etc/rspamd/
        fi
        chown _rspamd:_rspamd -R /var/lib/rspamd

        if [ -n "SYSLOG_HOST" ]; then
          echo "destination dst { syslog(\"${SYSLOG_HOST}\" transport(\"udp\")); };" > /etc/syslog-ng/conf.d/remote.conf
          echo "log { source(s_sys); destination(dst); };" >> /etc/syslog-ng/conf.d/remote.conf
          syslog-ng
	  echo "type = \"syslog\";" > /etc/rspamd/override.d/logging.inc
          echo "[RSPAMD] Output is set to remote syslog at ${SYSLOG_HOST}"
        else
          echo "type = \"console\";" > /etc/rspamd/override.d/logging.inc
        fi



        exec /usr/sbin/rspamd -f -u _rspamd -g _rspamd
