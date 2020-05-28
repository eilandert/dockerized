#!/bin/sh

        echo "[BOOTSTRAP] This docker image can be found on https://hub.docker.com/u/eilandert or https://github.com/eilandert/dockerized"

	# If there are no configfiles, copy them
	FIRSTRUN="/etc/nginx/nginx.conf"
	if [ ! -f ${FIRSTRUN} ]; then
          echo "[BOOTSTRAP] no configs found, populating default configs to /etc/nginx and /etc/modsecurity"
          cp -r /etc/nginx.orig/* /etc/nginx/
        fi

        chmod 777 /dev/stdout
        mkdir -p /run/nginx
	chown nginx:nginx /run/nginx

	echo "[BOOTSTRAP] starting NGINX, no more output here"

exec nginx -g 'daemon off;'
