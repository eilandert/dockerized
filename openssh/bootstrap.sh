#!/bin/sh

echo "[OPENSSH] This docker image can be found on https://hub.docker.com/u/eilandert and https://github.com/eilandert/dockerized"

if [ -n "${TZ}" ]; then
    rm -f /etc/timezone /etc/localtime
    echo "${TZ}" > /etc/timezone
    ln -s /usr/share/zoneinfo/${TZ} /etc/localtime
fi

FIRSTRUN="/etc/ssh/sshd_config"
if [ ! -f ${FIRSTRUN} ]; then
    echo "[OPENSSH] sshd_config not found, populating default configs to /etc/ssh"
    mkdir -p /etc/ssh
    cp -r /etc/ssh.orig/* /etc/ssh/
    sed -i s/"#PermitRootLogin prohibit-password"/"PermitRootLogin yes"/ /etc/ssh/sshd_config
    echo "root:toor" | chpasswd
fi

if [ -n "${SYSLOG_HOST}" ]; then
    mkdir -p /etc/syslog-ng/conf.d
    echo "destination dst { syslog(\"${SYSLOG_HOST}\" transport(\"udp\")); };" > /etc/syslog-ng/conf.d/remote.conf
    echo "log { source(s_sys); destination(dst); };" >> /etc/syslog-ng/conf.d/remote.conf
    syslog-ng --no-caps
    echo "[OPENSSH] Output is set to remote syslog at ${SYSLOG_HOST}"
else
    rm -f /etc/syslog-ng/conf.d/remote.conf
fi
    chmod 600 /etc/ssh/*key
    rm -rf /etc/ssh/sshd_config.d/20*

exec /usr/sbin/sshd -D -o ListenAddress=0.0.0.0
