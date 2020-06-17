#!/bin/sh

	if [ -n "TZ" ]; then
	  echo "${TZ}" > /etc/timezone
	fi

	mkdir -p /usr/local/etc/rspamd/override.d
	echo "type = \"file\";" > /usr/local/etc/rspamd/override.d/logging.inc
	echo "filename = \"/dev/stdout\";" >> /usr/local/etc/rspamd/override.d/logging.inc


exec /usr/local/bin/rspamd -f -u _rspamd -g _rspamd;
