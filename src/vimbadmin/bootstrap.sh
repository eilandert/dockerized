#!/bin/sh
set -e

echo "[VIMBADMIN] Angie-minimal + PHP-FPM ${PHPVERSION} :: https://github.com/eilandert/ViMbAdmin"

# ---- timezone (best-effort; /etc may be read-only) -------------------
if [ -n "${TZ}" ] && [ -w /etc ]; then
    rm -f /etc/timezone /etc/localtime
    echo "${TZ}" > /etc/timezone
    ln -sf "/usr/share/zoneinfo/${TZ}" /etc/localtime
fi

# ---- writable runtime dirs (var/ + configs are volumes; rest tmpfs) --
install -d -m 0750 -o phpfpm -g www-data \
    /run/php /var/log/php-fpm \
    "${INSTALL_PATH}/var" "${INSTALL_PATH}/var/templates_c" \
    "${INSTALL_PATH}/var/cache" "${INSTALL_PATH}/var/log" \
    "${INSTALL_PATH}/var/bruteforce" "${INSTALL_PATH}/application/configs" \
    2>/dev/null || true
# Angie temp dirs on tmpfs (/tmp) so the rootfs can be read-only.
install -d -m 0750 -o www-data -g www-data \
    /tmp/angie/client /tmp/angie/fastcgi /tmp/angie/proxy /tmp/angie/scgi /tmp/angie/uwsgi \
    2>/dev/null || true

# ---- first run: app config (from the image template) -----------------
INI="${INSTALL_PATH}/application/configs/application.ini"
if [ ! -f "${INI}" ]; then
    cp -rp "${INSTALL_PATH}/application/configs.orig/." "${INSTALL_PATH}/application/configs/"
    chown -R phpfpm:www-data "${INSTALL_PATH}/application/configs"
fi

# Per-deployment securitysalt: generated once, persisted in the configs
# volume. Never baked into the image (it encrypts 2FA secrets + seeds CSRF),
# and must stay stable across restarts -> only written if not already a real
# value. Appended to the active [docker : production] section (last in file).
if ! grep -qE '^[[:space:]]*securitysalt[[:space:]]*=[[:space:]]*"[0-9a-f]{16,}"' "${INI}"; then
    printf 'securitysalt = "%s"\n' "$(php -r 'echo bin2hex(random_bytes(32));')" >> "${INI}"
    chown phpfpm:www-data "${INI}"
    echo "[VIMBADMIN] generated securitysalt"
fi

# ---- Snuffleupagus ruleset: materialise into the writable var volume -
# (FPM's conf.d points sp.configuration_file at ${INSTALL_PATH}/var/...). This
# keeps /etc read-only and gives each deployment a unique secret_key.
SP="${INSTALL_PATH}/var/vimbadmin-strict.list"
if [ ! -f "${SP}" ]; then
    cp /usr/share/vimbadmin/vimbadmin-strict.list "${SP}"
    sed -i "s/CHANGE-ME-PER-DEPLOYMENT-0*/$(php -r 'echo bin2hex(random_bytes(32));')/" "${SP}"
    chown phpfpm:www-data "${SP}"
    chmod 0640 "${SP}"
    echo "[VIMBADMIN] generated Snuffleupagus secret_key"
fi

# ---- config test -----------------------------------------------------
php-fpm${PHPVERSION} -t
angie -t -c /etc/angie/angie.conf

# ---- run -------------------------------------------------------------
php-fpm${PHPVERSION} -D
exec angie -c /etc/angie/angie.conf -g 'daemon off;'
