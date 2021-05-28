#!/bin/bash

echo "[CLAMAV] This docker image can be found on https://hub.docker.com/u/eilandert and https://github.com/eilandert/dockerized"

CHECK="/config"
if [ -r ${CHECK} ]; then
    rm -rf /etc/clamav /etc/clamav-unofficial-sigs
    ln -s /config/clamav /etc/clamav
    ln -s /config/clamav-unofficial-sigs /etc/clamav-unofficial-sigs
fi

# If there are no configfiles, copy them
FIRSTRUN="/etc/clamav/clamd.conf"
if [ ! -f ${FIRSTRUN} ]; then
    echo "[CLAMAV] clamd.conf not found, populating default configs to /config"
    cp -r config.orig/* /etc
fi

echo -n "[CLAMAV] Running: "
clamd --version

if [ -n "${TZ}" ]; then
    echo "${TZ}" > /etc/timezone
fi

#echo "[CLAMAV] Updating the unofficial signatures updater from https://github.com/extremeshok/clamav-unofficial-sigs"
#clamav-unofficial-sigs.sh --upgrade 1>/dev/null 2>&1

# make stdout wordwriteable for docker console output
chmod 777 /dev/stdout
mkdir -p /var/run/clamav
chown clamav:clamav -R /var/run/clamav
chown clamav:clamav -R /var/lib/clamav

#Are there signatures?
CVD_FILE="/var/lib/clamav/main.cvd"
if [ ! -f ${CVD_FILE} ]; then
    echo "[CLAMAV] main.cvd not found, assuming there are no signatures..."
fi

echo "[CLAMAV] Starting ClamAV-milter"
clamav-milter

freshclam --user=clamav --no-warnings --foreground

#poor mans cron
echo "[CLAMAV] Starting updaters in the background"
while [ 1 ]; do
  /usr/local/sbin/clamav-unofficial-sigs.sh -s 1>/dev/null
  sleep 3600
done &
freshclam -d

echo "[CLAMAV] Starting clamd... Please wait while loading databases"

exec /usr/sbin/clamd --foreground=true
