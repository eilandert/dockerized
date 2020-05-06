#!/bin/sh
set -eu

  if [ -n "${NAMESERVER}" ]; then
   echo "nameserver ${NAMESERVER}" > /etc/resolv.conf
  fi


# If there are no configfiles, copy them
FIRSTRUN="/etc/nginx/nginx.conf"
if [ ! -f ${FIRSTRUN} ]; then
    echo "[bootstrap] no configs found, copying..."
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
echo "[bootstrap] starting NGINX, no more output here"

exec nginx -g 'daemon off;'
