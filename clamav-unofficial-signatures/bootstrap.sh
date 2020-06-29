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

# Make symlinks to /config so we can bind that
	rm -rf /etc/clamav && ln -s /config/clamav /etc/clamav
	rm -rf /etc/clamav-unofficial-sigs && ln -s /config/clamav-unofficial-sigs/ /etc/clamav-unofficial-sigs

# make stdout wordwriteable for docker console output
        chmod 777 /dev/stdout

#Are there signatures?
	CVD_FILE="/var/lib/clamav/main.cvd"
	if [ ! -f ${CVD_FILE} ]; then
	  echo "[CLAMAV] main.cvd not found, running clamav-unofficial-sigs in background"
          echo "[CLAMAV] waiting for internet to be up, pinging 8.8.8.8 with timeout of 60 secs"
          ping -c1 -W60 8.8.8.8
          /usr/local/sbin/clamav-unofficial-sigs -s &
	  echo "[CLAMAV] Running Freshclam in foreground once"
	  freshclam --user=clamav --no-warnings --foreground
	fi

	#poor mans cron
        echo "[CLAMAV] Starting updaters in the background"
	while [ 1 ]; do /usr/local/sbin/clamav-unofficial-sigs -s; sleep 3661; done &
	freshclam -d -c6 --user=clamav

	 echo "[CLAMAV] Starting clamd... Please wait while loading databases"

exec   /usr/sbin/clamd
