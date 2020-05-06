#!/bin/sh
set -eu

   if [ -n "${NAMESERVER}" ]; then
     echo "nameserver ${NAMESERVER}" > /etc/resolv.conf
   fi

   FIRSTRUN="/etc/postfix/main.cf"
    if [ ! -f ${FIRSTRUN} ]; then
      echo "[bootstrap] no configs found, copying..."
      mkdir -p /etc/postfix \
      && cp -r /etc/postfix.orig/* /etc/postfix/
    fi

   postconf maillog_file=/dev/stdout
   chmod 777 /dev/stdout

exec postfix start-fg
