#!/bin/bash

if [ -n "${TZ}" ]; then
    rm -f /etc/timezone /etc/localtime
    echo "${TZ}" > /etc/timezone
    ln -sfr /usr/share/zoneinfo/${TZ} /etc/localtime
fi

if [ -n "${SYSLOG_HOST}" ]; then
    mkdir -p /etc/syslog-ng/conf.d
    echo "destination dst { syslog(\"${SYSLOG_HOST}\" transport(\"udp\")); };" > /etc/syslog-ng/conf.d/remote.conf
    echo "log { source(s_sys); destination(dst); };" >> /etc/syslog-ng/conf.d/remote.conf
    syslog-ng --no-caps
    echo "[APTLY] Output is set to remote syslog at ${SYSLOG_HOST}"
else
    rm -f /etc/syslog-ng/conf.d/remote.conf
fi

#create sshd keys if needed (absent on first run)
bash /ssh-createkeys.sh 1>/dev/null

mkdir -p /aptly
chown aptly:aptly /aptly

if [ ! -f /aptly/config/aptly.conf ]; then
    mkdir -p /aptly/config
    sudo -u aptly aptly config show 1>/dev/null
    ln -sfr /aptly/.aptly.conf /aptly/config/aptly.conf
    sed -i s/"\.aptly"/repo/ /aptly/.aptly.conf
fi

if [ ! -d /aptly/.gnupg ]; then
    sudo -u aptly mkdir -p /aptly/.gnupg
    chmod 600 /aptly/.gnupg
fi

if [ ! -d /aptly/config/gnupg ]; then
    ln -sfr /aptly/.gnupg /aptly/config/gnupg
fi

if [ ! -d /aptly/.ssh ]; then
    sudo -u aptly mkdir -p /aptly/.ssh
fi

if [ ! -d /aptly/config/ssh ]; then
    ln -sfr /aptly/.ssh /aptly/config/ssh
fi

#if [ ! -d /aptly/config/sshd ]; then
#    cp -rp /aptly.orig/config/sshd /aptly/config
#fi
#ln -sfr /aptly/config/sshd /etc/ssh

#if [ ! -f /aptly/config/nginx/default ]; then
#   cp -rp /aptly.orig/config/nginx /aptly/config
#fi
#ln -sfr /aptly/config/nginx/default /etc/nginx/sites-enabled/default

if [ ! -d aptly/examples ]; then
    cp -rp /aptly.orig/examples /aptly/examples
fi

if [ ! -d /aptly/repo ]; then
    sudo -u aptly mkdir -p /aptly/repo
fi

if [ ! -d /aptly/incoming ]; then
    sudo -u aptly mkdir -p /aptly/incoming
else
    rm -f /aptly/incoming/*
fi


echo "[APTLY] Setting permissions"
chown aptly:aptly -R /aptly 
#&& chown root:root -R /aptly/config

if [ ! "${CLEANDBONSTART}" = "NO" ];
then
    echo "[APTLY] Cleaning DB"
    sudo -u aptly aptly db cleanup
fi

if [ ! "${STARTNGINX}" = "NO" ];
then
    nginx -t
    service nginx restart 1>/dev/null
fi

dockerid=$(hostname)
echo "[APTLY] For breaking into this docker: docker exec -it $dockerid bash"

exec /usr/sbin/sshd -D -o ListenAddress=0.0.0.0

