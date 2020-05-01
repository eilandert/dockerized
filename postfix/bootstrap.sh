#!/bin/sh
set -eu

   echo "[bootstrap] setting nameserver to ${NAMESERVER}"
   echo "nameserver ${NAMESERVER}" > /etc/resolv.conf

   FIRSTRUN="/etc/postfix/main.cf"
    if [ ! -f ${FIRSTRUN} ]; then
      echo "[bootstrap] no configs found, copying..."
      mkdir -p /etc/postfix \
      && cp -r /etc/postfix.orig/* /etc/postfix/
    fi

   DAILY_CRON="/etc/periodic/daily/postfix"
   echo "#!/bin/sh"                             >  ${DAILY_CRON}
   echo "/etc/postfix/cron.d/daily/*.sh"        >> ${DAILY_CRON}
   chmod +x ${DAILY_CRON}

   HOURLY_CRON="/etc/periodic/hourly/postfix"
   echo "#!/bin/sh"                             >  ${HOURLY_CRON}
   echo "/etc/postfix/cron.d/hourly/*.sh"       >> ${HOURLY_CRON}
   chmod +x ${HOURLY_CRON}

   crond
   postconf maillog_file=/dev/stdout

exec postfix start-fg