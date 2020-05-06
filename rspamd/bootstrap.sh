#!/bin/sh
set -eu

  if [ -n "${NAMESERVER}" ]; then
   echo "nameserver ${NAMESERVER}" > /etc/resolv.conf
  fi

    FIRSTRUN="/etc/rspamd/rspamd.conf"
    if [ ! -f ${FIRSTRUN} ]; then
      echo "[bootstrap] no configs found, copying..."
      mkdir -p /etc/rspamd \
      && cp -r /etc/rspamd.orig/* /etc/rspamd/

      if [ -n "${NAMESERVER}" ]; then
        echo "dns { nameserver = [\"hash:${NAMESERVER}\"] }" > /etc/rspamd/override.d/options.inc
      fi
    fi
   chown _rspamd:_rspamd -R /var/lib/rspamd

exec /usr/sbin/rspamd -f -u _rspamd -g _rspamd

