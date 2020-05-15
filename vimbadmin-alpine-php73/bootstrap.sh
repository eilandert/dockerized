#!/bin/sh

        echo "[BOOTSTRAP] This docker image can be found on"
        echo "[BOOTSTRAP] https://hub.docker.com/u/eilandert or https://github.com/eilandert/dockerized"
        echo "[BOOTSTRAP]"
        echo "[BOOTSTRAP] optional variables for this container:"
        echo "[BOOTSTRAP] NAMESERVER"

        #set nameserver if variable is set
        if [ -n "${NAMESERVER}" ]; then
                echo $nameserver ${NAMESERVER}" > /etc/resolv.conf
                echo "[BOOTSTRAP] wait for nameserver to be up with timeout of 60 secs"
                ping -c1 -W60 ${NAMESERVER}
        fi

	WORKDIR="/opt/vimbadmin"

	FIRSTRUN="${WORKDIR}/application/configs/application.ini"
	if [ ! -f ${FIRSTRUN} ]; then
          echo "[BOOTSTRAP] application.ini not found, populating default configs to ${WORKDIR}/application/configs/"
	  cp -rp ${WORKDIR}/application/configs.orig/* ${WORKDIR}/application/configs/
	  cp ${WORKDIR}/application/configs/application.ini.dist ${WORKDIR}/application/configs/application.ini
          echo "[docker : production]" >> ${WORKDIR}/application/configs/application.ini
	fi

        chown -R root:root ${WORKDIR}/application/configs/
        chown -R root:root ${WORKDIR}/
        chown -R apache:apache ${WORKDIR}/var
        mkdir -p /tmp
        chmod 1777 -R /tmp

	echo "[BOOTSTRAP] starting apache, please wait."

	exec /usr/sbin/httpd -DFOREGROUND
