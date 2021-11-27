#!/bin/sh

echo "[DOVECOT] This docker image can be found on https://hub.docker.com/u/eilandert and https://github.com/eilandert/dockerized"

if [ -n "${TZ}" ]; then
    rm -f /etc/timezone /etc/localtime
    echo "${TZ}" > /etc/timezone
    ln -s /usr/share/zoneinfo/${TZ} /etc/localtime
fi

FIRSTRUN="/etc/dovecot/dovecot.conf"
if [ ! -f ${FIRSTRUN} ]; then
    echo "[DOVECOT] no configs found, copying default configs to /etc/dovecot"
    mkdir -p /etc/dovecot && cp -r /etc/dovecot.orig/* /etc/dovecot/
fi

FIRSTRUN="/etc/nullmailer/defaultdomain"
if [ ! -f ${FIRSTRUN} ]; then
    echo "[APACHE-PHPFPM] no configs found, populating default configs to /etc/nullmailer"
    cp -r /etc/nullmailer.orig /etc/nullmailer
fi

#fix some weird issue with nullmailer
rm -f /var/spool/nullmailer/trigger
mkdir -p /var/spool/nullmailer/
/usr/bin/mkfifo /var/spool/nullmailer/trigger
/bin/chmod 0622 /var/spool/nullmailer/trigger
/bin/chown -R mail:mail /var/spool/nullmailer/ /etc/nullmailer
runuser -u mail /usr/sbin/nullmailer-send 1>/var/log/nullmailer.log 2>&1 &

if [ -n "${SYSLOG_HOST}" ]; then
    mkdir -p /etc/syslog-ng/conf.d
    echo "destination dst { syslog(\"${SYSLOG_HOST}\" transport(\"udp\")); };" > /etc/syslog-ng/conf.d/remote.conf
    echo "log { source(s_sys); destination(dst); };" >> /etc/syslog-ng/conf.d/remote.conf
    syslog-ng --no-caps
    echo "[DOVECOT] Output is set to remote syslog at ${SYSLOG_HOST}"
else
    rm -f /etc/syslog-ng/conf.d/remote.conf
fi

#if [ -n "${DB_DRIVER}" ]; then
#    sed -i s/"driver = .*"/"driver = ${DB_DRIVER}"/ /etc/dovecot/dovecot-sql.conf.ext
#    sed -i s/"connect = host=localhost user=vimbadmin password=password dbname=vimbadmin"/"connect = host=${DB_HOST} user=${DB_USERNAME} password=${DB_PASSWORD} dbname=${DB_DATABASE}"/ /etc/dovecot/dovecot-sql.conf.ext
#fi

if [ -n "${USE_VIMBADMIN}" ]; then
    cp -rp /opt/scripts/vimbadmin.orig /opt/scripts/vimbadmin
    sed -i s/"my \$driver .*"/"my \$driver   = \"${DB_DRIVER}\";"/ /opt/scripts/vimbadmin/*
    sed -i s/"my \$database .*"/"my \$database = \"${DB_DATABASE}\";"/ /opt/scripts/vimbadmin/*
    sed -i s/"my \$host .*"/"my \$host = \"${DB_HOST}\";"/ /opt/scripts/vimbadmin/*
    sed -i s/"my \$port .*"/"my \$port = \"${DB_PORT}\";"/ /opt/scripts/vimbadmin/*
    sed -i s/"my \$username .*"/"my \$username = \"${DB_USERNAME}\";"/ /opt/scripts/vimbadmin/*
    sed -i s/"my \$password .*"/"my \$password = \"${DB_PASSWORD}\";"/ /opt/scripts/vimbadmin/*
    /opt/scripts/vimbadmin/update_mailbox_size.pl &
fi

#sleep to avoid race conditions with other dockers like redis
if [ -n "${SLEEP}" ]; then
    sleep ${SLEEP};
fi

# test services
i=0
x=25
while [ 1 ]; do
    i=$(($i+1))
    HOST=$(eval echo \$WAIT_FOR_$i)
    if [ ! -n "${HOST}" ]; then
        break;
    fi
    wait-for-it.sh ${HOST} -t 3
    if [ "$?" -ne 0 ]; then
        echo "... ${HOST} is not reachable, trying again"
        i=$(($i-1))
        x=$(($x-1))
        if [ "${x}" -eq 0 ]; then
            echo "[DOVECOT] Nevermind, this is not going to work out! Goodbye!"
            exit 255;
        fi
    fi
done

case ${MALLOC} in
    jemalloc)
        export LD_PRELOAD=/usr/lib/x86_64-linux-gnu/libjemalloc.so.2
        ;;
    *|mimalloc)
        export LD_PRELOAD=/usr/lib/mimalloc-2.0/libmimalloc-secure-none.so.2.0
        ;;
    none)
        unset LD_PRELOAD
        ;;
esac



#echo "Automaticly reloading configs everyday to pick up new ssl certificates"
while [ 1 ]; do
    if [ -n "${USE_VIMBADMIN}" ]; then
        /opt/scripts/vimbadmin/update_mailbox_size.pl 
    fi
    sleep 1d;
    dovecot reload;
done &

echo "[DOVECOT] Pinging pyzor servers..."
/usr/bin/pyzor ping


chmod 777 /dev/stdout

exec /usr/sbin/dovecot -F

