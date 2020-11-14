#!/bin/sh

echo "[VIMBADMIN] This docker image can be found on https://hub.docker.com/u/eilandert and https://github.com/eilandert/dockerized"

WORKDIR="/opt/vimbadmin"

FIRSTRUN="${WORKDIR}/application/configs/application.ini"
if [ ! -f ${FIRSTRUN} ]; then
    echo "[VIMBADMIN] application.ini not found, populating default configs to ${WORKDIR}/application/configs/"
    cp -rp ${WORKDIR}/application/configs.orig/* ${WORKDIR}/application/configs/
    cp ${WORKDIR}/application/configs/application.ini.dist ${WORKDIR}/application/configs/application.ini
    chown -R apache:apache ${WORKDIR}/var
    echo "[docker : production]" >> ${WORKDIR}/application/configs/application.ini
else
    # 4-6-2020, change existing application.ini after upgrade to 3.2.0, removal from this file far in future.
    sed -i 's~"/../vendor/opensolutions/oss-framework/src/OSS/Resource"~"/../library/OSS/Resource"~' ${WORKDIR}/application/configs/application.ini
    sed -i 's~"/../vendor/opensolutions/oss-framework/src/OSS/Smarty/functions"~"/../library/OSS/Smarty/functions"~' ${WORKDIR}/application/configs/application.ini

    #copy new .dist to configs
    cp ${WORKDIR}/application/configs.orig/application.ini.dist ${WORKDIR}/application/configs/application.ini.dist
    echo "[docker : production]" >> ${WORKDIR}/application/configs/application.ini.dist
fi

if [ -n "${TZ}" ]; then
    echo "${TZ}" > /etc/timezone
fi


#fix for some apache lockfile problem.
mkdir -p /tmp && chmod 1777 -R /tmp

exec /usr/sbin/httpd -DFOREGROUND
