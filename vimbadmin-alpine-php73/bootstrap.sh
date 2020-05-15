#!/bin/sh


        if [ -n "${NAMESERVER}" ]; then
                echo "nameserver ${NAMESERVER}" > /etc/resolv.conf
        fi

WORKDIR="/opt/vimbadmin"

FIRSTRUN="${WORKDIR}/application/configs/application.ini"
if [ ! -f ${FIRSTRUN} ]; then
    echo "[bootstrap] application.ini not found (first run?), copying configfiles."
    cp -rp ${WORKDIR}/application/configs.orig/* ${WORKDIR}/application/configs/
    cp ${WORKDIR}/application/configs/application.ini.dist ${WORKDIR}/application/configs/application.ini
    echo "[docker : production]" >> ${WORKDIR}/application/configs/application.ini
fi
    chown -R root:root ${WORKDIR}/application/configs/
    chown -R root:root ${WORKDIR}/
    chown -R apache:apache ${WORKDIR}/var
    mkdir -p /tmp
    chmod 1777 -R /tmp

    echo "[bootstrap] starting apache, please wait."

exec /usr/sbin/httpd -DFOREGROUND
