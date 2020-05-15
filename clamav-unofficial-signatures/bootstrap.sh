#!/bin/bash

	if [ -n "${NAMESERVER}" ]; then
		echo $nameserver ${NAMESERVER}" > /etc/resolv.conf
	fi


# If there are no configfiles, copy them
	FIRSTRUN="/config/clamav/clamd.conf"
	if [ ! -f ${FIRSTRUN} ]; then
	  echo "[BOOTSTRAP] no configs found, copying..."
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
	  echo "[BOOTSTRAP] main.cvd not found found, running updaters"
          /usr/local/sbin/clamav-unofficial-sigs -s &
	  freshclam --user=clamav --no-warnings --foreground
	fi

	#poor mans cron
	while [ 1 ]; do sleep 3683; /usr/local/sbin/clamav-unofficial-sigs -s; done &
	freshclam -d -c24 --user=clamav

exec   /usr/sbin/clamd

