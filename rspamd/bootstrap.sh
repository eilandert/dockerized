#!/bin/sh

        echo "[RSPAMD] This docker image can be found on"
        echo "[RSPAMD] https://hub.docker.com/u/eilandert or https://github.com/eilandert/dockerized"

        FIRSTRUN="/etc/rspamd/rspamd.conf"
        if [ ! -f ${FIRSTRUN} ]; then
          echo "[RSPAMD] no configs found, populating default configs to /etc/rspamd"
          mkdir -p /etc/rspamd \
          && cp -r /etc/rspamd.orig/* /etc/rspamd/
        fi
        chown _rspamd:_rspamd -R /var/lib/rspamd

        exec /usr/sbin/rspamd -f -u _rspamd -g _rspamd
