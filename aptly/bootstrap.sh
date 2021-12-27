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
    aptly config show 1>/dev/null 2>&1
    mv ~/.aptly.conf /aptly/.aptly.conf
    sed -i s/"\.aptly"/repo/ /aptly/.aptly.conf
    chmod aptly:aptly /aptly/.aptly.conf
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

mkdir -p /aptly/examples
cp -rp /aptly.orig/examples/* /aptly/examples/

if [ ! -d /aptly/repo ]; then
    mkdir -p /aptly/repo
fi

if [ ! -d /aptly/incoming ]; then
    mkdir -p /aptly/incoming
else
    rm -f /aptly/incoming/*
fi

if [ ! -f /aptly/scripts/process-incoming.sh ]; then
    mkdir -p /aptly/scripts
    cp -rp /aptly/examples/process-incoming.sh /aptly/scripts/
fi
chmod +x /aptly/scripts/process-incoming.sh

chown aptly:aptly -R /aptly

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
