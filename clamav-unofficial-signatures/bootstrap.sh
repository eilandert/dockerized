#!/bin/bash

echo "[CLAMAV] This docker image can be found on https://hub.docker.com/u/eilandert and https://github.com/eilandert/dockerized"

# If there are no configfiles, copy them
FIRSTRUN="/config/clamav/clamd.conf"
if [ ! -f ${FIRSTRUN} ]; then
    echo "[CLAMAV] clamd.conf not found, populating default configs to /config"
    mkdir -p /config \
        && cp -r config.orig/* /config/
fi

if [ -n "${TZ}" ]; then
    echo "${TZ}" > /etc/timezone
fi

# Make symlinks to /config so we can bind to /config
rm -rf /etc/clamav && ln -s /config/clamav /etc/clamav
rm -rf /etc/clamav-unofficial-sigs && ln -s /config/clamav-unofficial-sigs/ /etc/clamav-unofficial-sigs

# copy updated configfiles
cp /config.orig/clamav-unofficial-sigs/master.conf /config/clamav-unofficial-sigs/master.conf
cp /config.orig/clamav-unofficial-sigs/user.conf /config/clamav-unofficial-sigs/user.conf

# make stdout wordwriteable for docker console output
chmod 777 /dev/stdout

#Are there signatures?
CVD_FILE="/var/lib/clamav/main.cvd"
if [ ! -f ${CVD_FILE} ]; then
    echo "[CLAMAV] main.cvd not found"
    echo "[CLAMAV] Running Freshclam in foreground for one time only. This can take a while."
    freshclam --user=clamav --no-warnings --foreground
fi

#poor mans cron
echo "[CLAMAV] Starting updaters in the background"
while [ 1 ]; do /usr/local/sbin/clamav-unofficial-sigs -s ; sleep 3661; done &
freshclam -d -c6 --user=clamav

echo "[CLAMAV] Starting clamd... Please wait while loading databases"

exec   /usr/sbin/clamd
