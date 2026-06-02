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

# ---- app config dir (mountable so users can adjust application.ini) --
# The image ships the defaults in configs.orig (the live configs dir is moved
# there at build time). On start:
#   * no application.ini yet  -> first run / empty mounted volume: seed the
#     whole config dir from the shipped defaults.
#   * application.ini present  -> user's own config: leave it untouched, but
#     drop the latest shipped default next to it as application.ini.orig so
#     they can diff after an image bump.
CONF="${INSTALL_PATH}/application/configs"
ORIG="${INSTALL_PATH}/application/configs.orig"
INI="${CONF}/application.ini"
if [ ! -f "${INI}" ]; then
    cp -rp "${ORIG}/." "${CONF}/"
    chown -R phpfpm:www-data "${CONF}"
    echo "[VIMBADMIN] seeded config dir from shipped defaults"
else
    cp -p "${ORIG}/application.ini" "${CONF}/application.ini.orig"
    chown phpfpm:www-data "${CONF}/application.ini.orig"
    echo "[VIMBADMIN] refreshed application.ini.orig (shipped default, for diffing)"
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

# ---- purge stale Smarty compiled templates on every (re)start --------
# templates_c holds compiled .php from the skin/templates. After an image
# bump the source templates change but the compiled copies live in the
# persistent var volume -> wipe them so the new code is recompiled fresh.
rm -rf "${INSTALL_PATH}/var/templates_c"/* 2>/dev/null || true

# ---- config test -----------------------------------------------------
php-fpm${PHPVERSION} -t
angie -t -c /etc/angie/angie.conf

# ---- run -------------------------------------------------------------
php-fpm${PHPVERSION} -D
exec angie -c /etc/angie/angie.conf -g 'daemon off;'
