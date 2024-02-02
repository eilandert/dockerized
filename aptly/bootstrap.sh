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
fi


if [ ! "${STARTNGINX}" = "NO" ];
then
# If there are no configfiles, copy them
FIRSTRUN="/etc/nginx/nginx.conf"
if [ ! -f ${FIRSTRUN} ]; then
    echo "[NGINX] no configs found, populating default configs to /etc/nginx"
    cp -r /etc/nginx.orig/* /etc/nginx/
fi
fi

# If you bind /etc/ssh the dir will be empty, so place a new copy
if [ ! -f "/etc/ssh/sshd_config" ];
then
    rm -rf /etc/ssh/*
    cp -rp /etc/ssh.orig/* /etc/ssh
fi
#create sshd keys if needed (absent on first run)
bash /ssh-createkeys.sh 1>/dev/null
chmod 600 /etc/ssh/*key
chown root:root -R /etc/ssh

mkdir -p /aptly
chown aptly:aptly /aptly

if [ ! -f /aptly/.aptly.conf ]; then
    sudo -u aptly aptly config show 1>/dev/null 2>&1
    sed -i s/"\.aptly"/repo/ /aptly/.aptly.conf
    chown aptly:aptly /aptly/.aptly.conf
fi

if [ ! -d /aptly/.gnupg ]; then
    mkdir -p /aptly/.gnupg
    chmod 600 /aptly/.gnupg
    chown aptly:aptly /aptly/.gnupg
fi

if [ ! -d /aptly/.ssh ]; then
    mkdir -p /aptly/.ssh
    chmod 600 /aptly/.ssh
    chown aptly:aptly /aptly.ssh
fi

if [ ! -d /aptly/repo ]; then
    mkdir -p /aptly/repo
fi

if [ ! -d /aptly/incoming ]; then
    mkdir -p /aptly/incoming
else
    rm -rf /aptly/incoming/*
fi

if [ ! -d /aptly/examples ]; then
    mkdir -p /aptly/examples
fi
cp -rp /aptly.orig/examples/* /aptly/examples/

if [ ! -f /aptly/bin/process-incoming.sh ]; then
    mkdir -p /aptly/bin
    cp -rp /aptly/examples/process-incoming.sh /aptly/bin/
fi
chmod +x /aptly/bin/process-incoming.sh

chown aptly:aptly -R /aptly &

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

service cron restart

dockerid=$(hostname)
echo "[APTLY] For breaking into this docker: docker exec -it $dockerid bash"

exec /usr/sbin/sshd -D
