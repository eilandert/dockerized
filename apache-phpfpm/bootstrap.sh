#!/bin/sh

        echo "[APACHE-PHPFM] This docker image can be found on https://hub.docker.com/u/eilandert or https://github.com/eilandert/dockerized"

        chmod 777 /dev/stdout

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

	if [ ! "${MODE}" = "multi" ]; then
          FIRSTRUN="/etc/php/${PHPVERSION}/fpm/php-fpm.conf"
          if [ ! -f ${FIRSTRUN} ]; then
          echo "[APACHE-PHPFM] no configs found, populating default configs to /etc/php"
          cp -r /etc/php.orig/* /etc/php/
          fi
	fi

        FIRSTRUN="/etc/nullmailer/defaultdomain"
        if [ ! -f ${FIRSTRUN} ]; then
          echo "[APACHE-PHPFM] no configs found, populating default configs to /etc/nullmailer"
          cp -r /etc/nullmailer.orig/* /etc/nullmailer
        fi

        #fix some weird issue with nullmailer
        rm -f /var/spool/nullmailer/trigger
        /usr/bin/mkfifo /var/spool/nullmailer/trigger
        /bin/chmod 0622 /var/spool/nullmailer/trigger
        /bin/chown -R mail:mail /var/spool/nullmailer/ /etc/nullmailer
        runuser -u mail /usr/sbin/nullmailer-send 1>/var/log/nullmailer.log 2>&1 &

        if [ "${MODE}" = "multi" ]; then
          #fix some weird issue with php-fpm
          if [ ! -x /run/php ]; then
            mkdir -p /run/php
            chown www-data:www-data /run/php
            chmod 755 /run/php
	  fi

	  #make sure no php-fpm is running, enabling them later on request
	  service php5.6-fpm stop 1>/dev/null 2>&1
	  service php7.2-fpm stop 1>/dev/null 2>&1
	  service php7.4-fpm stop 1>/dev/null 2>&1
	  service php8.0-fpm stop 1>/dev/null 2>&1

	  if [ "${PHP56}" = "yes" ]; then
            FIRSTRUN="/etc/php/5.6/fpm/php-fpm.conf"
            if [ ! -f ${FIRSTRUN} ]; then
              echo "[APACHE-PHPFM] no configs found, populating default configs to /etc/php/5.6"
	      mkdir -p /etc/php/5.6
              cp -r /etc/php.orig/5.6/* /etc/php/5.6
	    fi
	    php-fpm5.6 -v
	    php-fpm5.6 -t
	    service php5.6-fpm restart 1>/dev/null 2>&1
	  fi

          if [ "${PHP72}" = "yes" ]; then
            FIRSTRUN="/etc/php/7.2/fpm/php-fpm.conf"
            if [ ! -f ${FIRSTRUN} ]; then
              echo "[APACHE-PHPFM] no configs found, populating default configs to /etc/php/7.2"
              mkdir -p /etc/php/7.2
              cp -r /etc/php.orig/7.2/* /etc/php/7.2
            fi
            php-fpm7.2 -v
            php-fpm7.2 -t
            service php7.2-fpm restart 1>/dev/null 2>&1
          fi

          if [ "${PHP74}" = "yes" ]; then
            FIRSTRUN="/etc/php/7.4/fpm/php-fpm.conf"
            if [ ! -f ${FIRSTRUN} ]; then
              echo "[APACHE-PHPFM] no configs found, populating default configs to /etc/php/7.4"
              mkdir -p /etc/php/7.4
              cp -r /etc/php.orig/7.4/* /etc/php/7.4
            fi
            php-fpm7.4 -v
            php-fpm7.4 -t
            service php7.4-fpm restart 1>/dev/null 2>&1
          fi

          if [ "${PHP80}" = "yes" ]; then
            FIRSTRUN="/etc/php/8.0/fpm/php-fpm.conf"
            if [ ! -f ${FIRSTRUN} ]; then
              echo "[APACHE-PHPFM] no configs found, populating default configs to /etc/php/8.0"
              mkdir -p /etc/php/8.0
              cp -r /etc/php.orig/8.0/* /etc/php/8.0
            fi
            php-fpm8.0 -v
            php-fpm8.0 -t
            service php8.0-fpm restart 1>/dev/null 2>&1
          fi
	fi

	if [ "${MODE}" = "fpm" ]; then
    	  #fix some weird issue with php-fpm
	  if [ ! -x /run/php ]; then
            mkdir -p /run/php
            chown www-data:www-data /run/php
            chmod 755 /run/php
          fi
	  a2dismod php${PHPVERSION} 1>/dev/null 2>&1
	  a2enconf php${PHPVERSION}-fpm 1>/dev/null 2>&1
	  a2dismod mpm_prefork 1>/dev/null 2>&1
	  a2enmod mpm_event 1>/dev/null 2>&1
          php-fpm${PHPVERSION} -v
          php-fpm${PHPVERSION} -t
          service php${PHPVERSION}-fpm restart 1>/dev/null 2>&1
	fi

        if [ "${MODE}" = "mod" ]; then
          service php${PHPVERSION}-fpm stop 1>/dev/null 2>&1
	  a2enmod php${PHPVERSION} 1>/dev/null 2>&1
	  a2disconf php${PHPVERSION}-fpm 1>/dev/null 2>&1
	  a2dismod mpm_event 1>/dev/null 2>&1
	  a2enmod mpm_prefork 1>/dev/null 2>&1
	  php${PHPVERSION} -v
	fi

	if [ -n "${A2ENMOD}" ]; then
	  a2enmod ${A2ENMOD} 1>/dev/null 2>&1
	fi

        if [ -n "${A2DISMOD}" ]; then
	  a2dismod ${A2DISMOD} 1>/dev/null 2>&1
        fi

        if [ -n "${A2ENCONF}" ]; then
	  a2enconf ${A2ENCONF} 1>/dev/null 2>&1
        fi

        if [ -n "${A2DISCONF}" ]; then
	  a2disconf ${A2DISCONF} 1>/dev/null 2>&1
        fi

        if [ "${CACHE}" = "yes" ]; then
          mkdir -p /var/cache/apache2/mod_cache_disk
          chmod 755 /var/cache/apache2/mod_cache_disk
          chown -R www-data:www-data /var/cache/apache2/mod_cache_disk
          a2enmod cache_disk 1>/dev/null 2>&1
          #htcacheclean -d${CACHE_INTERVAL} -l${CACHE_SIZE} -t -i -p /var/cache/apache2/mod_cache_disk
        else
          if [ -f /etc/apache2/mods-enabled/cache_disk.load ]; then
            a2dismod cache cache_disk 1>/dev/null 2>&1
          fi
        fi

	apachectl -v
	echo "Checking configs:"
	apachectl configtest

	if [ -f /etc/apache2/mods-enabled/ssl.load ]; then
	  while [ 1 ]; do sleep 1d; apachectl graceful; done &
	fi

exec /usr/sbin/apache2ctl -DFOREGROUND

