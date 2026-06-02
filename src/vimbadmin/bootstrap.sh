#!/bin/sh
set -e

echo "[VIMBADMIN] Angie-minimal + PHP-FPM ${PHPVERSION} :: https://github.com/eilandert/ViMbAdmin"

# ---- timezone --------------------------------------------------------
if [ -n "${TZ}" ]; then
    rm -f /etc/timezone /etc/localtime
    echo "${TZ}" > /etc/timezone
    ln -sf "/usr/share/zoneinfo/${TZ}" /etc/localtime
fi

# ---- first run: populate writable config trees -----------------------
if [ ! -f /etc/angie/angie.conf ]; then
    mkdir -p /etc/angie
    cp -a /etc/angie.orig/. /etc/angie/ 2>/dev/null || true
fi

# Place the Angie config + fastcgi include (shipped in the image).
install -D -m 0644 /etc/angie.orig/angie.conf /etc/angie/angie.conf
[ -f /vimb_fastcgi.inc ] && install -D -m 0644 /vimb_fastcgi.inc /etc/angie/vimb_fastcgi.inc

# ---- first run: app config -------------------------------------------
INI="${INSTALL_PATH}/application/configs/application.ini"
if [ ! -f "${INI}" ]; then
    cp -rp "${INSTALL_PATH}/application/configs.orig/." "${INSTALL_PATH}/application/configs/"
    chown -R phpfpm:www-data "${INSTALL_PATH}/var" "${INSTALL_PATH}/application/configs"
fi

# Generate a unique securitysalt on first run and persist it in the (mounted)
# configs volume. Never baked into the image -> not shared across deployments.
# It is appended to the active [docker : production] section, which is the last
# section in the file. It encrypts 2FA TOTP secrets and seeds CSRF, so it must
# be stable across restarts (hence: only ever written once).
if ! grep -qE '^[[:space:]]*securitysalt[[:space:]]*=[[:space:]]*"[0-9a-f]{16,}"' "${INI}"; then
    SALT="$(php -r 'echo bin2hex(random_bytes(32));')"
    printf 'securitysalt = "%s"\n' "${SALT}" >> "${INI}"
    chown phpfpm:www-data "${INI}"
    echo "[VIMBADMIN] generated securitysalt"
fi

# ---- Snuffleupagus: ensure a unique secret_key -----------------------
SP=/etc/php/${PHPVERSION}/php-snuffleupagus/vimbadmin-strict.list
if [ -f "${SP}" ] && grep -q 'CHANGE-ME-PER-DEPLOYMENT' "${SP}"; then
    KEY="$(php -r 'echo bin2hex(random_bytes(32));')"
    sed -i "s/CHANGE-ME-PER-DEPLOYMENT-0*/${KEY}/" "${SP}"
    echo "[VIMBADMIN] generated Snuffleupagus secret_key"
fi

# ---- runtime dirs ----------------------------------------------------
install -d -m 0750 -o phpfpm -g www-data /run/php /var/log/php-fpm "${INSTALL_PATH}/var/templates_c" "${INSTALL_PATH}/var/cache" "${INSTALL_PATH}/var/log" "${INSTALL_PATH}/var/bruteforce" 2>/dev/null || true

# ---- config test -----------------------------------------------------
php-fpm${PHPVERSION} -t
angie -t -c /etc/angie/angie.conf

# ---- run -------------------------------------------------------------
php-fpm${PHPVERSION} -D
exec angie -c /etc/angie/angie.conf -g 'daemon off;'
