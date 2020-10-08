#!/bin/sh

        echo "[APACHE-PHPFM] This docker image can be found on https://hub.docker.com/u/eilandert or https://github.com/eilandert/dockerized"

        if [ -n "${TZ}" ]; then
         rm /etc/timezone /etc/localtime
         echo "${TZ}" > /etc/timezone
         ln -s /usr/share/zoneinfo/${TZ} /etc/localtime
        fi


        # If there are no configfiles, copy them
        FIRSTRUN="/etc/apache2/apache2.conf"
        if [ ! -f ${FIRSTRUN} ]; then
          echo "[APACHE-PHPFM] no configs found, populating default configs to /etc/apache2"
          cp -r /etc/apache2.orig/* /etc/apache2/
        fi

        FIRSTRUN="/etc/php/7.4/fpm/php-fpm.conf"
        if [ ! -f ${FIRSTRUN} ]; then
          echo "[APACHE-PHPFM] no configs found, populating default configs to /etc/php"
          cp -r /etc/php.orig/* /etc/php/
        fi

        FIRSTRUN="/etc/nullmailer/defaultdomain"
        if [ ! -f ${FIRSTRUN} ]; then
          echo "[APACHE-PHPFM] no configs found, populating default configs to /etc/nullmailer"
          cp -r /etc/nullmailer.orig/* /etc/nullmailer
        fi

	#fix some weird issue with php-fpm
	if [ ! -x /run/php ]; then
          mkdir -p /run/php
          chown www-data:www-data /run/php
          chmod 755 /run/php
        fi
        service php7.4-fpm restart 1>/dev/null 2>&1

	#fix some weird issue with nullmailer
	rm -f /var/spool/nullmailer/trigger
	/usr/bin/mkfifo /var/spool/nullmailer/trigger
	/bin/chmod 0622 /var/spool/nullmailer/trigger
	/bin/chown -R mail:mail /var/spool/nullmailer/ /etc/nullmailer 
        runuser -u mail /usr/sbin/nullmailer-send 1>/var/log/nullmailer.log 2>&1 &

        if [ ${CACHE} = yes ]; then
            #fix some weird issue with apache2 mod_cache
            mkdir -p /var/cache/apache2/mod_cache_disk
            chown -R www-data:www-data /var/cache/apache2/mod_cache_disk
            a2enmod cache_disk 1>/dev/null 2>&1
            htcacheclean -d${CACHE_INTERVAL} -l${CACHE_SIZE} -t -i -p /var/cache/apache2/mod_cache_disk
        else
          if [ -f /etc/apache2/mods-enabled/cache_disk.load ]; then
            a2dismod cache_disk 1>/dev/null 2>&1
            a2dismod cache 1>/dev/null 2>&1
          fi
        fi

        chmod 777 /dev/stdout

	apachectl configtest

exec /usr/sbin/apache2ctl -DFOREGROUND

