#!/bin/sh

        echo "[VIMBADMIN] This docker image can be found on https://hub.docker.com/u/eilandert and https://github.com/eilandert/dockerized"

	WORKDIR="/opt/vimbadmin"

	FIRSTRUN="${WORKDIR}/application/configs/application.ini"
	if [ ! -f ${FIRSTRUN} ]; then
          echo "[VIMBADMIN] application.ini not found, populating default configs to ${WORKDIR}/application/configs/"
	  cp -rp ${WORKDIR}/application/configs.orig/* ${WORKDIR}/application/configs/
	  cp ${WORKDIR}/application/configs/application.ini.dist ${WORKDIR}/application/configs/application.ini
          echo "[docker : production]" >> ${WORKDIR}/application/configs/application.ini
	fi

        chown -R root:root ${WORKDIR}/application/configs/
        chown -R root:root ${WORKDIR}/
        chown -R apache:apache ${WORKDIR}/var
        mkdir -p /tmp
        chmod 1777 -R /tmp

	echo "[VIMBADMIN] Starting apache, please wait.. This can take some time."

	exec /usr/sbin/httpd -DFOREGROUND
