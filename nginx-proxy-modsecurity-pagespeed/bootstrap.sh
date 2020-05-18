#!/bin/sh

        echo "[BOOTSTRAP] This docker image can be found on https://hub.docker.com/u/eilandert or https://github.com/eilandert/dockerized"

        #set nameserver if variable is set
        if [ -n "${NAMESERVER}" ]; then
                echo "nameserver ${NAMESERVER}" > /etc/resolv.conf
        fi

	# If there are no configfiles, copy them
	FIRSTRUN="/etc/nginx/nginx.conf"
	if [ ! -f ${FIRSTRUN} ]; then
          echo "[BOOTSTRAP] no configs found, populating default configs to /etc/nginx and /etc/modsecurity"
          cp -r /etc/nginx.orig/* /etc/nginx/
          cp -r /etc/modsecurity.orig/* /etc/modsecurity/
        fi

        chmod 777 /dev/stdout

	echo "[BOOTSTRAP] starting NGINX, no more output here"

exec nginx -g 'daemon off;'
