#!/bin/bash

	echo "[BOOTSTRAP] This docker image can be found on https://hub.docker.com/u/eilandert / https://github.com/eilandert/dockerized"

	#set nameserver if variable is set.  (but please use dns: in dockercompose).
	if [ -n "${NAMESERVER}" ]; then
		echo "nameserver ${NAMESERVER}" > /etc/resolv.conf
	fi

# If there are no configfiles, copy them
	FIRSTRUN="/config/clamav/clamd.conf"
	if [ ! -f ${FIRSTRUN} ]; then
	  echo "[BOOTSTRAP] clamd.conf not found, populating default configs to /config"
	  mkdir -p /config \
	  && cp -r config.orig/* /config/
	fi

# Make symlinks to /config so we can bind that
	rm -rf /etc/clamav && ln -s /config/clamav /etc/clamav
	rm -rf /etc/clamav-unofficial-sigs && ln -s /config/clamav-unofficial-sigs/ /etc/clamav-unofficial-sigs

# make stdout wordwriteable for docker console output
        chmod 777 /dev/stdout

#Are there signatures?
	CVD_FILE="/var/lib/clamav/main.cvd"
	if [ ! -f ${CVD_FILE} ]; then
	  echo "[BOOTSTRAP] main.cvd not found, running clamav-unofficial-sigs in background"
          echo "[BOOTSTRAP] waiting for internet to be up, pinging 8.8.8.8 with timeout of 60 secs"
          ping -c1 -W60 8.8.8.8
          /usr/local/sbin/clamav-unofficial-sigs -s &
	  echo "[BOOTSTRAP] Running Freshclam in foreground once"
	  freshclam --user=clamav --no-warnings --foreground
	fi

	#poor mans cron
        echo "[BOOTSTRAP] Starting updaters in the background"
	while [ 1 ]; do /usr/local/sbin/clamav-unofficial-sigs -s; sleep 3661; done &
	freshclam -d -c6 --user=clamav

	 echo "[BOOTSTRAP] Starting clamd... Please wait while loading databases"

exec   /usr/sbin/clamd
