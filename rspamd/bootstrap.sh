#!/bin/sh
set -eux

    FIRSTRUN="/etc/rspamd/rspamd.conf"
    if [ ! -f ${FIRSTRUN} ]; then
      echo "[bootstrap] no configs found, copying..."
      mkdir -p /etc/rspamd \
      && cp -r /etc/rspamd.orig/* /etc/rspamd/
    fi

   echo "nameserver ${NAMESERVER}" > /etc/resolv.conf

    chown _rspamd:_rspamd -R /var/lib/rspamd

exec /usr/sbin/rspamd -f -u _rspamd -g _rspamd

