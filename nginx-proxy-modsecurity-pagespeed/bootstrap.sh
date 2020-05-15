#!/bin/sh

        echo "[BOOTSTRAP] This docker image can be found on"
        echo "[BOOTSTRAP] https://hub.docker.com/u/eilandert or https://github.com/eilandert/dockerized"
        echo "[BOOTSTRAP]"
        echo "[BOOTSTRAP] optional variables for this container:"
        echo "[BOOTSTRAP] NAMESERVER"

        #set nameserver if variable is set
        if [ -n "${NAMESERVER}" ]; then
                echo "nameserver ${NAMESERVER}" > /etc/resolv.conf
                echo "[BOOTSTRAP] wait for nameserver to be up with timeout of 60 secs"
                ping -c1 -W60 ${NAMESERVER}
        fi

	# If there are no configfiles, copy them
	FIRSTRUN="/etc/nginx/nginx.conf"
	if [ ! -f ${FIRSTRUN} ]; then
          echo "[BOOTSTRAP] no configs found, populating default configs to /etc/nginx and /etc/modsecurity"
          cp -r /etc/nginx.orig/* /etc/nginx/
          cp -r /etc/modsecurity.orig/* /etc/modsecurity/
        fi

        chmod 777 /dev/stdout


echo ""
echo "-----------------------------------------------------------------"
echo "  For more info see:                                             "
echo "  https://launchpad.net/~eilander/+archive/ubuntu/nginx          "
echo "  https://github.com/eilandert/dockerized                        "
echo "  https://hub.docker.com/r/eilandert/nginx-modsecurity3-pagespeed"
echo "-----------------------------------------------------------------"
echo ""
echo "[BOOTSTRAP] starting NGINX, no more output here"

exec nginx -g 'daemon off;'
