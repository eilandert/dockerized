#!/bin/sh
set -e

echo "[VIMBADMIN] Angie-minimal + PHP-FPM ${PHPVERSION}"
echo "[VIMBADMIN] App fork : https://github.com/eilandert/ViMbAdmin"
echo "[VIMBADMIN] Image src: https://github.com/eilandert/dockerized/tree/master/src/vimbadmin"
echo "[VIMBADMIN] ---------------------------------------------------------------"
echo "[VIMBADMIN] Security profile: runs UNPRIVILEGED (no root), cap_drop ALL +"
echo "[VIMBADMIN]   no-new-privileges + AppArmor, read-only rootfs, Angie on :8080."
echo "[VIMBADMIN] Because the container has NO root and CANNOT chown, every writable"
echo "[VIMBADMIN]   mount must already be owned by uid 997 (phpfpm) : gid 33 (www-data)."
echo "[VIMBADMIN]   Named volumes inherit this automatically. For bind mounts / tmpfs:"
echo "[VIMBADMIN]     host : sudo chown -R 997:33 <your bind dir>"
echo "[VIMBADMIN]     tmpfs: --tmpfs /run:uid=997,gid=33,mode=0770 (and likewise /tmp)"
echo "[VIMBADMIN]   A 'Permission denied' on boot = a writable mount not owned 997:33."
echo "[VIMBADMIN] ---------------------------------------------------------------"

# ---- timezone (best-effort; /etc may be read-only) -------------------
if [ -n "${TZ}" ] && [ -w /etc ]; then
    rm -f /etc/timezone /etc/localtime
    echo "${TZ}" > /etc/timezone
    ln -sf "/usr/share/zoneinfo/${TZ}" /etc/localtime
fi

# ---- writable runtime dirs (var/ + configs are volumes; rest tmpfs) --
# The container runs UNPRIVILEGED (compose `user: phpfpm:www-data`, cap_drop
# ALL), so we cannot chown: the writable volumes (var, configs, run, tmp,
# php-log) MUST be pre-owned by the runtime uid/gid on the host. We only
# create subdirs here -- as their owner -- so no CHOWN/DAC_OVERRIDE is needed.
# `install` without -o/-g inherits the current (phpfpm) user; failures on an
# already-correct dir are harmless, so keep them non-fatal.
install -d -m 0750 \
    /run/php /var/log/php-fpm \
    "${INSTALL_PATH}/var" "${INSTALL_PATH}/var/templates_c" \
    "${INSTALL_PATH}/var/cache" "${INSTALL_PATH}/var/log" \
    "${INSTALL_PATH}/var/session" \
    "${INSTALL_PATH}/var/bruteforce" "${INSTALL_PATH}/application/configs" \
    2>/dev/null || true
# Angie temp dirs on tmpfs (/tmp) so the rootfs can be read-only.
install -d -m 0750 \
    /tmp/angie/client /tmp/angie/fastcgi /tmp/angie/proxy /tmp/angie/scgi /tmp/angie/uwsgi \
    2>/dev/null || true

# ---- app config -----------------------------------------------------
# Mount/keep a full application.ini yourself (start from the shipped
# application.ini.dist). On an empty mount we seed it from the baked defaults;
# otherwise we leave it untouched and only refresh application.ini.orig for
# diffing. A per-deployment securitysalt is appended if one isn't present.
CONF="${INSTALL_PATH}/application/configs"
ORIG="${INSTALL_PATH}/application/configs.orig"
INI="${CONF}/application.ini"

# NB: no chown anywhere below -- the process already runs as phpfpm:www-data,
# so every file it creates is correctly owned. The container has cap_drop ALL
# and could not chown even if it wanted to.
if [ ! -f "${INI}" ]; then
    cp -rp "${ORIG}/." "${CONF}/"
    echo "[VIMBADMIN] seeded config dir from shipped defaults"
else
    cp -p "${ORIG}/application.ini" "${CONF}/application.ini.orig"
    echo "[VIMBADMIN] application.ini left as-is (refreshed .orig)"
fi
# Per-deployment securitysalt.
if ! grep -qE '^[[:space:]]*securitysalt[[:space:]]*=[[:space:]]*"[0-9a-f]{16,}"' "${INI}"; then
    printf 'securitysalt = "%s"\n' "$(php -n -r 'echo bin2hex(random_bytes(32));')" >> "${INI}"
    echo "[VIMBADMIN] generated securitysalt"
fi

# ---- Snuffleupagus ruleset: materialise into the writable var volume -
# (FPM's conf.d points sp.configuration_file at ${INSTALL_PATH}/var/...). This
# keeps /etc read-only and gives each deployment a unique secret_key.
SP="${INSTALL_PATH}/var/vimbadmin-strict.list"
if [ ! -f "${SP}" ]; then
    cp /usr/share/vimbadmin/vimbadmin-strict.list "${SP}"
    sed -i "s/CHANGE-ME-PER-DEPLOYMENT-0*/$(php -n -r 'echo bin2hex(random_bytes(32));')/" "${SP}"
    chmod 0640 "${SP}"
    echo "[VIMBADMIN] generated Snuffleupagus secret_key"
fi

# NB: we do NOT wipe var/templates_c. Smarty's compile_check (on by default)
# recompiles any template whose source mtime changed, so an image bump
# recompiles only what changed, lazily — wiping them all just forced a cold
# recompile of every template on each restart.

# ---- database schema auto-migrate -----------------------------------
# Apply any pending additive Doctrine schema changes on every start, so a code
# bump that adds a table/column goes live without a manual "Update schema" click.
# Idempotent (no pending SQL == no-op) and non-fatal: if the DB is not reachable
# yet, the app still boots and the next restart (or the Maintenance button)
# applies it. Records the DBVERSION in the database_version table.
echo "[VIMBADMIN] checking database schema..."
php "${INSTALL_PATH}/bin/vimbtool.php" -a maintenance.cli-schema-update --verbose 2>&1 \
    | sed 's/^/[VIMBADMIN][schema] /' \
    || echo "[VIMBADMIN] schema auto-migrate skipped (DB not ready?) — retries next start"

# ---- queue: drain on start ------------------------------------------
# On container start, kick the mailbox-task queue once so any work left PENDING
# from before a restart starts draining immediately (respecting
# queue.runner.max_concurrent via the DB lease). Backgrounded + non-fatal — a
# cron is still the guaranteed periodic runner.
echo "[VIMBADMIN] triggering queue runner on start..."
( php "${INSTALL_PATH}/bin/vimbtool.php" -a queue.cli-run >/dev/null 2>&1 || true ) &

# ---- config test -----------------------------------------------------
php-fpm${PHPVERSION} -t
angie -t -c /etc/angie/angie.conf

# ---- run -------------------------------------------------------------
php-fpm${PHPVERSION} -D
exec angie -c /etc/angie/angie.conf -g 'daemon off;'
