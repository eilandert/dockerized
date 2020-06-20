#!/bin/sh

        echo "[NGINX-PROXY] This docker image can be found on https://hub.docker.com/u/eilandert or https://github.com/eilandert/dockerized"
	echo "[NGINX-PROXY] The NGINX packages can be found on https://launchpad.net/~eilander/+archive/ubuntu/nginx"

	# If there are no configfiles, copy them
	FIRSTRUN="/etc/nginx/nginx.conf"
	if [ ! -f ${FIRSTRUN} ]; then
          echo "[NGINX-PROXY] no configs found, populating default configs to /etc/nginx and /etc/modsecurity"
          cp -r /etc/nginx.orig/* /etc/nginx/
          cp -r /etc/modsecurity.orig/* /etc/modsecurity/
        fi

        chmod 777 /dev/stdout

	echo "[NGINX-PROXY] starting NGINX, no more output here"

exec nginx -g 'daemon off;'
