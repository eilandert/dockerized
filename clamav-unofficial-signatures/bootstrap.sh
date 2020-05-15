#!/bin/bash

	echo "[BOOTSTRAP] This docker image can be found on"
	echo "[BOOTSTRAP] https://hub.docker.com/u/eilandert or https://github.com/eilandert/dockerized"
	echo "[BOOTSTRAP]"
	echo "[BOOTSTRAP] optional variables for this container:"
	echo "[BOOTSTRAP] NAMESERVER"

	#set nameserver if variable is set
	if [ -n "${NAMESERVER}" ]; then
		echo "$nameserver ${NAMESERVER}" > /etc/resolv.conf
		echo "[BOOTSTRAP] wait for nameserver to be up with timeout of 60 secs"
		ping -c1 -W60 ${NAMESERVER}
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

	chmod 777 /dev/stdout

#Are there signatures?
	CVD_FILE="/var/lib/clamav/main.cvd"
	if [ ! -f ${CVD_FILE} ]; then
	  echo "[BOOTSTRAP] main.cvd not found"
	  echo "[BOOTSTRAP] Running clamav-unofficial-sigs in background"
          /usr/local/sbin/clamav-unofficial-sigs -s &
	  echo "[BOOTSTRAP] Running Freshclam in foreground once"
	  freshclam --user=clamav --no-warnings --foreground
	fi

	#poor mans cron
	while [ 1 ]; do sleep 3683; /usr/local/sbin/clamav-unofficial-sigs -s; done &
	freshclam -d -c24 --user=clamav

exec   /usr/sbin/clamd

