#!/bin/sh

chmod 777 /dev/stdout

if [ -n "${TZ}" ]; then
    rm /etc/timezone /etc/localtime
    echo "${TZ}" > /etc/timezone
    ln -s /usr/share/zoneinfo/${TZ} /etc/localtime
fi

FIRSTRUN="/etc/nullmailer/defaultdomain"
if [ ! -f ${FIRSTRUN} ]; then
    echo "[PHP-FPM] no configs found, populating default configs to /etc/nullmailer"
    cp -r /etc/nullmailer.orig/* /etc/nullmailer
fi

#fix some weird issue with nullmailer
rm -f /var/spool/nullmailer/trigger
rm -f /var/spool/nullermailer/queue/core
/usr/bin/mkfifo /var/spool/nullmailer/trigger
/bin/chmod 0622 /var/spool/nullmailer/trigger
/bin/chown -R mail:mail /var/spool/nullmailer/ /etc/nullmailer
runuser -u mail /usr/sbin/nullmailer-send 1>/var/log/nullmailer.log 2>&1 &

dockerid=$(hostname)
echo "[DOCKER-CMS] For breaking into this docker: docker exec -it $dockerid bash"

exec while(1) { sleep 3600; }
