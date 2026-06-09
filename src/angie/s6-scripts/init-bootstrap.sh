#!/bin/sh
# s6 oneshot: all one-time container setup, split out of the old bootstrap.sh.
# The long-running processes that used to be `&`/`exec` at the tail are now
# separate s6 longruns: php-fpm, angie, nullmailer, ticket-reload. This script
# must finish (exit 0) before those start; a FATAL config error aborts the boot.
set -eu

echo "[ANGIE] Find documentation for this Docker image at https://deb.myguard.nl/angie-dockerized/"
echo "[ANGIE] For information about the ANGIE packages, please visit https://deb.myguard.nl/angie-modules/"

# Timezone
if [ -n "${TZ:-}" ]; then
    rm -f /etc/timezone /etc/localtime
    echo "${TZ}" > /etc/timezone
    ln -s /usr/share/zoneinfo/${TZ} /etc/localtime
fi

# First-run config copy
if [ ! -f /etc/angie/angie.conf ]; then
    echo "[ANGIE] Default configurations are being copied to /etc/angie and /etc/modsecurity as no existing configs were found."
    cp -r /etc/angie.orig/* /etc/angie/
fi
cp -r /etc/modsecurity.orig/* /etc/modsecurity/

# Snakeoil fallback cert
if [ ! -f /etc/ssl/certs/ssl-cert-snakeoil.pem ] || [ ! -f /etc/ssl/private/ssl-cert-snakeoil.key ]; then
    if command -v make-ssl-cert >/dev/null 2>&1; then
        make-ssl-cert generate-default-snakeoil --force-overwrite 2>/dev/null || true
    fi
fi

# PHP-dependent setup
if [ -n "${PHPVERSION:-}" ]; then
    if [ ! -f /etc/nullmailer/defaultdomain ]; then
        echo "[ANGIE] Default configurations are being copied to /etc/nullmailer as no existing configs were found."
        cp -r /etc/nullmailer.orig/* /etc/nullmailer
    fi
    find /var/spool/nullmailer -type f -name "core" -delete
    rm -f /var/spool/nullmailer/trigger
    /usr/bin/mkfifo /var/spool/nullmailer/trigger
    /bin/chmod 0622 /var/spool/nullmailer/trigger
    /bin/chown -R mail:mail /var/spool/nullmailer/ /etc/nullmailer

    if [ ! -x /run/php ]; then
        mkdir -p /run/php
        chown phpfpm:www-data /run/php
        chmod 750 /run/php
    fi

    # The phpfpm worker user must share the www-data group so it can write site
    # files owned <editor>:www-data (WP plugin/theme/core + translation updates).
    # Without this, WordPress's filesystem-method probe falls back to prompting
    # for FTP credentials. Idempotent.
    if id phpfpm >/dev/null 2>&1 && ! id -nG phpfpm | grep -qw www-data; then
        usermod -aG www-data phpfpm
    fi

    if [ ! -f /usr/bin/composer ]; then
        ( cd /tmp && php composer-setup.php --quiet && mv composer.phar /usr/bin/composer ) 2>/dev/null || true
    fi

    # Stable socket symlink for the healthz /fpm-ping probe. Points at the
    # primary (single-PHP) or highest (MULTI) www pool socket. The target need
    # not exist yet — angie resolves the path at request time, after fpm starts.
    _hzver="${PHPVERSION}"
    if [ "${MODE:-}" = "MULTI" ]; then
        for v in 8.5:PHP85 8.4:PHP84 8.3:PHP83 8.2:PHP82 8.1:PHP81 \
                 8.0:PHP80 7.4:PHP74 7.2:PHP72 5.6:PHP56; do
            ver="${v%%:*}"; var="${v##*:}"; eval "val=\${$var:-}"
            [ "${val}" = "YES" ] && { _hzver="${ver}"; break; }
        done
    fi
    ln -sf "/run/php/php${_hzver}-fpm.sock" /run/php/healthz-fpm.sock

    # PHP config copy (single + MULTI). Mirrors the old startphp() first-run copy.
    cp -rn /etc/php.orig/* /etc/php 2>/dev/null || true
    copy_php_cfg() {
        _v="$1"
        if [ ! -f "/etc/php/${_v}/fpm/php-fpm.conf" ]; then
            echo "[ANGIE] Default PHP configurations are being copied to /etc/php/${_v}."
            mkdir -p "/etc/php/${_v}"
            cp -r "/etc/php.orig/${_v}/"* "/etc/php/${_v}" 2>/dev/null || true
        fi
        php-fpm${_v} -t || { echo "[ANGIE] ---> FATAL: php-fpm${_v} -t failed."; exit 1; }
    }
    if [ "${MODE:-}" = "MULTI" ]; then
        SETPHP=0
        for v in 5.6:PHP56 7.2:PHP72 7.4:PHP74 8.0:PHP80 8.1:PHP81 \
                 8.2:PHP82 8.3:PHP83 8.4:PHP84 8.5:PHP85; do
            ver="${v%%:*}"; var="${v##*:}"
            eval "val=\${$var:-}"
            [ "${val}" = "YES" ] && { copy_php_cfg "${ver}"; SETPHP=1; }
        done
        if [ "${SETPHP}" = 0 ]; then
            echo "[ANGIE] ---> MULTI-PHP image but no PHPnn=YES env set. Aborting boot."
            exit 1
        fi
    else
        copy_php_cfg "${PHPVERSION}"
    fi
fi

# Refresh static helper files from .orig
[ -f /etc/angie.orig/mime.types ] && cp -p /etc/angie.orig/mime.types /etc/angie/mime.types
[ -f /etc/angie.orig/angie.conf-packaged ] && cp -p /etc/angie.orig/angie.conf-packaged /etc/angie/angie.conf-packaged
[ -f /etc/angie.orig/angie.conf-original ] && cp -p /etc/angie.orig/angie.conf-original /etc/angie/angie.conf-original
if [ -d /etc/angie.orig/scripts ] && [ -n "$(ls -A /etc/angie.orig/scripts 2>/dev/null)" ]; then
    mkdir -p /etc/angie/scripts
    cp -p /etc/angie.orig/scripts/. /etc/angie/scripts/ 2>/dev/null || cp -rp /etc/angie.orig/scripts/* /etc/angie/scripts/
fi
if [ -d /etc/angie.orig/snippets ] && [ -n "$(ls -A /etc/angie.orig/snippets 2>/dev/null)" ]; then
    mkdir -p /etc/angie/snippets
    cp -rp /etc/angie.orig/snippets/* /etc/angie/snippets/
fi

# Modules sync + reorder
mkdir -p /etc/angie/modules-available
rm -f /etc/angie/modules-available/*
if [ -d /usr/share/angie/modules-available ] && [ -n "$(ls -A /usr/share/angie/modules-available 2>/dev/null)" ]; then
    cp -rp /usr/share/angie/modules-available/* /etc/angie/modules-available/
fi
chmod +x /etc/angie/scripts/reorder-modules.sh
/etc/angie/scripts/reorder-modules.sh

# NGX_MODULES default-all warning + lua strip
if [ -n "${MODULES:-}" ]; then NGX_MODULES="${MODULES}"; fi
if [ -z "${NGX_MODULES:-}" ]; then
    if [ ! -e "/etc/angie/modules-enabled/.quiet" ]; then
        echo "[ANGIE] ---> Without NGX_MODULES defined, all modules initialize; removing lua modules that need extra config."
        rm -f /etc/angie/modules-enabled/50-mod-http-lua.conf
        rm -f /etc/angie/modules-enabled/50-mod-stream-lua.conf
    fi
fi

# Config validation gate — FATAL on failure
angie -V 2>&1 | grep -v configure | grep -v SNI || true
echo "[ANGIE] Verifying configurations using the command angie -t"
if ! angie -t; then
    echo "[ANGIE] ---> FATAL: angie -t failed — the configuration is invalid (see above). Aborting boot."
    exit 1
fi

# TLS session-ticket key (first generation; rotation in the ticket-reload longrun)
TICKET_KEY=/run/angie/ticket.key
mkdir -p /run/angie 2>/dev/null || true
if [ ! -f "${TICKET_KEY}" ]; then
    openssl rand 80 > "${TICKET_KEY}" 2>/dev/null && chmod 0600 "${TICKET_KEY}" || true
fi

# MALLOC selection → ld_preload file the angie + php-fpm longruns source.
case "${MALLOC:-jemalloc}" in
    mimalloc) echo "/usr/lib/x86_64-linux-gnu/libmimalloc-secure.so" > /run/angie/ld_preload ;;
    none)     : > /run/angie/ld_preload ;;
    *)        echo "/usr/lib/x86_64-linux-gnu/libjemalloc.so.2" > /run/angie/ld_preload ;;
esac

echo "[ANGIE] init-bootstrap complete; handing off to s6-supervised services."
exit 0
