#!/bin/sh

        chmod 777 /dev/stdout

        echo "[NGINX-PROXY] This docker image can be found on https://hub.docker.com/u/eilandert or https://github.com/eilandert/dockerized"
	echo "[NGINX-PROXY] The NGINX packages can be found on https://launchpad.net/~eilander/+archive/ubuntu/nginx"

        if [ -n "${TZ}" ]; then
         rm /etc/timezone /etc/localtime
         echo "${TZ}" > /etc/timezone
         ln -s /usr/share/zoneinfo/${TZ} /etc/localtime
        fi

	# If there are no configfiles, copy them
	FIRSTRUN="/etc/nginx/nginx.conf"
	if [ ! -f ${FIRSTRUN} ]; then
          echo "[NGINX-PROXY] no configs found, populating default configs to /etc/nginx and /etc/modsecurity"
          cp -r /etc/nginx.orig/* /etc/nginx/
          cp -r /etc/modsecurity.orig/* /etc/modsecurity/
        fi

	nginx -V 2>&1 | grep -v configure
	nginx -t

        #echo "Automaticly reloading configs everyday to pick up new ssl certificates"
        while [ 1 ]; do sleep 1d; nginx -s reload; done &

exec nginx -g 'daemon off;'
