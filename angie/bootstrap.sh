#!/bin/sh

chmod 777 /dev/stdout

echo "[ANGIE] Find documentation for this Docker image at https://deb.myguard.nl/angie-dockerized/"
echo "[ANGIE] For information about the ANGIE packages, please visit https://deb.myguard.nl/angie-modules/"

# Set timezone
if [ -n "${TZ}" ]; then
    rm -f /etc/timezone /etc/localtime
    echo "${TZ}" > /etc/timezone
    ln -s /usr/share/zoneinfo/${TZ} /etc/localtime
fi

# If there are no configfiles, copy them
FIRSTRUN="/etc/angie/angie.conf"
if [ ! -f ${FIRSTRUN} ]; then
    echo "[ANGIE] Default configurations are being copied to /etc/angie and /etc/modsecurity as no existing configs were found."
    cp -r /etc/angie.orig/* /etc/angie/
    cp -r /etc/modsecurity.orig/* /etc/modsecurity/
fi

#check if PHP is installed, else skip the whole block
if [ -n "${PHPVERSION}" ]; then

    FIRSTRUN="/etc/nullmailer/defaultdomain"
    if [ ! -f ${FIRSTRUN} ]; then
    echo "[ANGIE] Default configurations are being copied to /etc/nullmailer as no existing configs were found."
        cp -r /etc/nullmailer.orig/* /etc/nullmailer
    fi

    #fix some weird issue with nullmailer
    find /var/spool/nullmailer -type f -name "core" -delete
    rm -f /var/spool/nullmailer/trigger
    /usr/bin/mkfifo /var/spool/nullmailer/trigger
    /bin/chmod 0622 /var/spool/nullmailer/trigger
    /bin/chown -R mail:mail /var/spool/nullmailer/ /etc/nullmailer
    runuser -u mail /usr/sbin/nullmailer-send 1>/var/log/nullmailer.log 2>&1 &

    if [ ! -x /run/php ]; then
        mkdir -p /run/php
        chown www-data:www-data /run/php
        chmod 755 /run/php
    fi

    COMPOSERPATH="/usr/bin/composer"
    if [ ! -f ${COMPOSERPATH} ]; then
        cd /tmp
        php composer-setup.php --quiet
        mv composer.phar ${COMPOSERPATH}
    fi
fi

cp -p /etc/angie.orig/mime.types /etc/angie/mime.types
cp -p /etc/angie.orig/angie.conf-packaged /etc/angie/angie.conf-packaged
cp -p /etc/angie.orig/angie.conf-original /etc/angie/angie.conf-original
cp -p /etc/angie.orig/scripts/* /etc/angie/scripts
cp -p /etc/angie.orig/snippets/* /etc/angie/snippets

# Make sure all available modules are available outside of docker and remove modules which aren't there (anymore)
mkdir -p /etc/angie/modules-available
rm -f /etc/angie/modules-available/*
cp -rp /usr/share/angie/modules-available/* /etc/angie/modules-available

#reorder modules and symlink them to /usr/share/angie/modules-enabled
chmod +x /etc/angie/scripts/reorder-modules.sh
/etc/angie/scripts/reorder-modules.sh

#check if PHP is installed, else skip the whole block
# PHPBLOCK
if [ -n "${PHPVERSION}" ]; then

    SETPHP=0
    startphp()
    {
        # set PHPVERSION for MULTI mode
        PHPVERSION="$1"
        FIRSTRUN="/etc/php/${PHPVERSION}/fpm/php-fpm.conf"
        if [ ! -f ${FIRSTRUN} ]; then
            echo "[ANGIE] Default PHP configurations are being copied to /etc/php/${PHPVERSION} as no existing PHP configs were found."
            mkdir -p /etc/php/${PHPVERSION}
            cp -r /etc/php.orig/${PHPVERSION}/* /etc/php/${PHPVERSION}
        fi
        php-fpm${PHPVERSION} -v 2>&1 | grep -v Zend | grep -v Copy
        php-fpm${PHPVERSION} -t
        service php${PHPVERSION}-fpm restart 1>/dev/null 2>&1 &
        SETPHP=1
    }

    cp -rn /etc/php.orig/* /etc/php

    #SINGLE PHP IMAGES
    if [ "${MODE}" = "FPM" ] && [ ! "${MODE}" = "MULTI" ]; then
        startphp "${PHPVERSION}"
    fi
    #MULTI PHP IMAGES
    if [ "${MODE}" = "MULTI" ] && [ "${PHP56}" = "YES" ]; then
        startphp "5.6"
    fi
    if [ "${MODE}" = "MULTI" ] && [ "${PHP72}" = "YES" ]; then
        startphp "7.2"
    fi
    if [ "${MODE}" = "MULTI" ] && [ "${PHP74}" = "YES" ]; then
        startphp "7.4"
    fi
    if [ "${MODE}" = "MULTI" ] && [ "${PHP80}" = "YES" ]; then
        startphp "8.0"
    fi
    if [ "${MODE}" = "MULTI" ] && [ "${PHP81}" = "YES" ]; then
        startphp "8.1"
    fi
    if [ "${MODE}" = "MULTI" ] && [ "${PHP82}" = "YES" ]; then
        startphp "8.2"
    fi
    if [ "${MODE}" = "MULTI" ] && [ "${PHP83}" = "YES" ]; then
        startphp "8.3"
    fi
    if [ "${PHPVERSION}" = "MULTI" ] && [ "${SETPHP}" = 0 ]; then
        echo "[ANGIE] --->"
        echo "[ANGIE] ---> You have obtained the MULTI-PHP version of the Docker, however..."
        echo "[ANGIE] ---> No environment variable for PHP56, PHP74, PHP80, PHP81, PHP82, or PHP83 has been set"
        echo "[ANGIE] ---> Uncertain of the next steps, the process will now exit..."
	echo "[ANGIE] --->"
        exit
    fi
fi
# /PHPBLOCK

if [ -n "${MODULES}" ]; then
    $NGX_MODULES = ${MODULES};
fi

if [ ! -n "${NGX_MODULES}" ]; then
    if [ ! -e "/etc/angie/modules/enabled/.quiet" ]; then
        echo "[ANGIE] --->"
	echo "[ANGIE] ---> Without NGX_MODULES defined in the environment, all modules will be initialized"
        echo "[ANGIE] ---> This may lead to issues, reduced performance, or failure to start"
        echo "[ANGIE] ---> It's advised to define NGX_MODULES or manually remove entries from /etc/angie/modules-enabled"
	echo "[ANGIE] ---> Removing mod-http-lua.conf and mod-stream-lua.conf, as those requires additional configuration to start"
        echo "[ANGIE] ---> To suppress this message and behaviour please touch /etc/angie/modules-enabled/.quiet"
        echo "[ANGIE] --->"
        rm /etc/angie/modules-enabled/50-mod-http-lua.conf
        rm /etc/angie/modules-enabled/50-mod-stream-lua.conf
    fi
fi

angie -V 2>&1 | grep -v configure | grep -v SNI
echo "[ANGIE] Verifying configurations using the command angie -t"
angie -t

echo "[ANGIE] This docker is set to reload every 24 hours to pick up new SSL certificates."
while [ 1 ]; do sleep 1d; /usr/sbin/angie -s reload; done &

# Setup the MALLOC of choice.
case ${MALLOC} in
    *|jemalloc)
        export LD_PRELOAD=/usr/lib/x86_64-linux-gnu/libjemalloc.so.2
        ;;
    mimalloc)
        export LD_PRELOAD=/usr/lib/x86_64-linux-gnu/libmimalloc-secure.so
        ;;
    none)
        unset LD_PRELOAD
        ;;
esac

exec /usr/sbin/angie -g 'daemon off;'
