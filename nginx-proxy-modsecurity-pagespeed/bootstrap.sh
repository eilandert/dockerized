#!/bin/sh
#set -ex

# If there are no configfiles, copy them
FIRSTRUN="/etc/nginx/nginx.conf"
if [ ! -f ${FIRSTRUN} ]; then
    echo "[bootstrap] no configs found, copying..."
    cp -r /etc/nginx.orig/* /etc/nginx/
    cp -r /etc/modsecurity.orig/* /etc/modsecurity/
fi

echo ""
echo "-----------------------------------------------------------------"
echo "  For more info see:                                             "
echo "  https://launchpad.net/~eilander/+archive/ubuntu/nginx          "
echo "  https://github.com/eilandert/dockerized-nginx                  "
echo "  https://hub.docker.com/r/eilandert/nginx-modsecurity3-pagespeed"
echo "-----------------------------------------------------------------"
echo ""
echo "[bootstrap] starting NGINX, no more output here"

exec nginx -g 'daemon off;'
