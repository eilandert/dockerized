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

        FIRSTRUN="/etc/rspamd/rspamd.conf"
        if [ ! -f ${FIRSTRUN} ]; then
          echo "[BOOTSTRAP] no configs found, populating default configs to /etc/rspamd"
          mkdir -p /etc/rspamd \
          && cp -r /etc/rspamd.orig/* /etc/rspamd/

          if [ -n "${NAMESERVER}" ]; then
            echo "[BOOTSTRAP] First run, setting nameserver in /etc/rspamd/override.d/options.inc"
            echo "dns { nameserver = [\"hash:${NAMESERVER}\"] }" > /etc/rspamd/override.d/options.inc
          fi
        fi
        chown _rspamd:_rspamd -R /var/lib/rspamd

        exec /usr/sbin/rspamd -f -u _rspamd -g _rspamd

