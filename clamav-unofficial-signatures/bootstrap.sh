#!/bin/bash
set -eu

  if [ -z ${NAMESERVER} ]; then
   echo "nameserver ${NAMESERVER}" > /etc/resolv.conf
  fi

# If there are no configfiles, copy them
    FIRSTRUN="/config/clamav/clamd.conf"
    if [ ! -f ${FIRSTRUN} ]; then
      echo "[bootstrap] no configs found, copying..."
      mkdir -p /config \
      && cp -r config.orig/* /config/
    fi
    rm -rf /etc/clamav \
      && ln -s /config/clamav /etc/clamav
    rm -rf /etc/clamav-unofficial-sigs \
      && ln -s /config/clamav-unofficial-sigs/ /etc/clamav-unofficial-sigs
    chmod 777 /dev/stdout

    while [ 1 ]; do /usr/local/sbin/clamav-unofficial-sigs -s; sleep 3683; done &

#Are there signatures?
    CVD_FILE="/var/lib/clamav/main.cvd"
    if [ ! -f ${CVD_FILE} ]; then
      echo "[bootstrap] No signatures found, running updater"
      freshclam --user=clamav --no-warnings --foreground
    fi

    freshclam -d -c24  --user=clamav

exec   /usr/sbin/clamd

