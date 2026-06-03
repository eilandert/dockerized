#!/bin/bash
# =============================================================================
# Roundcube container entrypoint.
#
# Runs as root so angie can bind :80 and setuid its workers to `roundcube`,
# php-fpm's master can setuid its workers to `roundcube`, and we can chown the
# mounted config dir (root-owned host bind) to the runtime user. The actual
# worker processes (angie, php-fpm) drop to the unprivileged roundcube uid.
#
# Writable locations: /tmp (sockets, pid, RC temp), /var/roundcube/config
# (generated config.inc.php + override). External DB (mariadb/pgsql) mandatory.
# =============================================================================
set -euo pipefail

PHPVERSION="${PHPVERSION:-8.5}"
INSTALLDIR="${INSTALLDIR:-/var/www/html}"

# Roundcube config search path. php-fpm workers get this from the pool's
# env[RCUBE_CONFIG_PATH], but the CLI bin/*.sh scripts we run below are NOT
# php-fpm children — they need it exported here or they read only the empty
# install config/ dir, find no db_dsnw, and fall back to a localhost socket
# ([2002] No such file or directory). Export it for the whole script.
export RCUBE_CONFIG_PATH="/var/roundcube/config/:config/"

log() { echo "[ROUNDCUBE] $*"; }
log "Image: https://hub.docker.com/u/eilandert — source: https://github.com/eilandert/dockerized"

# ---------------------------------------------------------------------------
# Writable runtime dirs (all under the /tmp tmpfs or the config/db volumes)
# ---------------------------------------------------------------------------
: "${ROUNDCUBEMAIL_TEMP_DIR:=/tmp/roundcube-temp}"

mkdir -p /tmp/run \
         /tmp/angie/client-body /tmp/angie/proxy /tmp/angie/fastcgi \
         "${ROUNDCUBEMAIL_TEMP_DIR}" /var/roundcube/config

# We run as root, so fix ownership on the writable mounts (the config bind
# mount is typically root-owned on the host) and the tmpfs scratch dirs, so
# the roundcube-uid workers and CLI scripts can write.
chown -R roundcube:roundcube /var/roundcube/config "${ROUNDCUBEMAIL_TEMP_DIR}" /tmp/run /tmp/angie

# ---------------------------------------------------------------------------
# Database wiring (secrets > env). An external DB (mysql/mariadb or pgsql) is
# mandatory — there is no sqlite fallback. Fail fast if nothing is configured.
# ---------------------------------------------------------------------------
[ -f /run/secrets/roundcube_db_user ]     && ROUNDCUBEMAIL_DB_USER="$(cat /run/secrets/roundcube_db_user)"
[ -f /run/secrets/roundcube_db_password ] && ROUNDCUBEMAIL_DB_PASSWORD="$(cat /run/secrets/roundcube_db_password)"

: "${ROUNDCUBEMAIL_DB_TYPE:=mysql}"
case "${ROUNDCUBEMAIL_DB_TYPE}" in
    pgsql)
        : "${ROUNDCUBEMAIL_DB_HOST:=postgres}"
        : "${ROUNDCUBEMAIL_DB_PORT:=5432}"
        ;;
    mysql)
        : "${ROUNDCUBEMAIL_DB_HOST:=mysql}"
        : "${ROUNDCUBEMAIL_DB_PORT:=3306}"
        ;;
    *)
        log "FATAL: unsupported ROUNDCUBEMAIL_DB_TYPE='${ROUNDCUBEMAIL_DB_TYPE}' (use mysql or pgsql)"
        exit 1
        ;;
esac
: "${ROUNDCUBEMAIL_DB_NAME:=roundcubemail}"
if [ -z "${ROUNDCUBEMAIL_DB_USER:-}" ] || [ -z "${ROUNDCUBEMAIL_DB_PASSWORD:-}" ]; then
    log "FATAL: ROUNDCUBEMAIL_DB_USER / ROUNDCUBEMAIL_DB_PASSWORD must be set"
    exit 1
fi
: "${ROUNDCUBEMAIL_DSNW:=${ROUNDCUBEMAIL_DB_TYPE}://${ROUNDCUBEMAIL_DB_USER}:${ROUNDCUBEMAIL_DB_PASSWORD}@${ROUNDCUBEMAIL_DB_HOST}:${ROUNDCUBEMAIL_DB_PORT}/${ROUNDCUBEMAIL_DB_NAME}}"
wait-for-it.sh -q "${ROUNDCUBEMAIL_DB_HOST}:${ROUNDCUBEMAIL_DB_PORT}" -t 30

# ---------------------------------------------------------------------------
# Generate config.inc.php into the writable config volume. RC finds it via
# env[RCUBE_CONFIG_PATH] = /var/roundcube/config/:config/ (set in the pool);
# defaults.inc.php + mimetypes.php come from the read-only install config/.
# ---------------------------------------------------------------------------
: "${ROUNDCUBEMAIL_DEFAULT_HOST:=localhost}"
: "${ROUNDCUBEMAIL_DEFAULT_PORT:=143}"
: "${ROUNDCUBEMAIL_SMTP_SERVER:=localhost}"
: "${ROUNDCUBEMAIL_SMTP_PORT:=587}"
: "${ROUNDCUBEMAIL_PLUGINS:=archive,zipdownload,managesieve,newmail_notifier,password,new_user_dialog}"
: "${ROUNDCUBEMAIL_SKIN:=elastic}"
# IMAP/SMTP TLS handling. Verification is ON by default (secure transport).
# Three ways to deal with an internal mail server:
#   1. (best) Point DEFAULT_HOST/SMTP at a name covered by the cert's SAN, keep
#      verification on — nothing to set here.
#   2. Pin the issuing CA: set ROUNDCUBEMAIL_SSL_CA=/path/to/ca.pem (mount it).
#      Verification stays ON, just against your own CA.
#   3. (last resort, insecure) ROUNDCUBEMAIL_SSL_VERIFY=0 disables peer
#      verification — only for a trusted LAN segment; it allows MITM. Must be
#      set explicitly; it is NOT the default.
: "${ROUNDCUBEMAIL_SSL_VERIFY:=1}"
: "${ROUNDCUBEMAIL_SSL_CA:=}"

ROUNDCUBEMAIL_PLUGINS_PHP="$(echo "${ROUNDCUBEMAIL_PLUGINS}" | sed -E "s/[, ]+/', '/g")"
ROUNDCUBEMAIL_DES_KEY="$(test -f /run/secrets/roundcube_des_key && cat /run/secrets/roundcube_des_key || head -c 24 /dev/urandom | base64 | head -c 24)"

if [ -n "${ROUNDCUBEMAIL_SSL_CA}" ]; then
    # CA pinning — verification stays ON, against the supplied CA bundle.
    SSL_OPTS_PHP="\$config['imap_conn_options'] = ['ssl' => ['verify_peer' => true, 'verify_peer_name' => true, 'cafile' => '${ROUNDCUBEMAIL_SSL_CA}']];
\$config['smtp_conn_options'] = ['ssl' => ['verify_peer' => true, 'verify_peer_name' => true, 'cafile' => '${ROUNDCUBEMAIL_SSL_CA}']];"
elif [ "${ROUNDCUBEMAIL_SSL_VERIFY}" = "0" ] || [ "${ROUNDCUBEMAIL_SSL_VERIFY}" = "false" ]; then
    log "WARNING: ROUNDCUBEMAIL_SSL_VERIFY=0 — IMAP/SMTP TLS peer verification DISABLED (MITM possible). Prefer a matching cert or ROUNDCUBEMAIL_SSL_CA."
    SSL_OPTS_PHP="\$config['imap_conn_options'] = ['ssl' => ['verify_peer' => false, 'verify_peer_name' => false, 'allow_self_signed' => true]];
\$config['smtp_conn_options'] = ['ssl' => ['verify_peer' => false, 'verify_peer_name' => false, 'allow_self_signed' => true]];"
else
    SSL_OPTS_PHP="// TLS peer verification enabled (default). Use ROUNDCUBEMAIL_SSL_CA to pin a private CA, or ROUNDCUBEMAIL_SSL_VERIFY=0 to disable (insecure)."
fi

umask 077
cat > /var/roundcube/config/config.inc.php <<PHP
<?php
\$config = [];
\$config['db_dsnw']      = '${ROUNDCUBEMAIL_DSNW}';
\$config['default_host'] = '${ROUNDCUBEMAIL_DEFAULT_HOST}';
\$config['default_port'] = '${ROUNDCUBEMAIL_DEFAULT_PORT}';
\$config['smtp_server']  = '${ROUNDCUBEMAIL_SMTP_SERVER}';
\$config['smtp_port']    = '${ROUNDCUBEMAIL_SMTP_PORT}';
\$config['des_key']      = '${ROUNDCUBEMAIL_DES_KEY}';
\$config['temp_dir']     = '${ROUNDCUBEMAIL_TEMP_DIR}';
\$config['plugins']      = ['${ROUNDCUBEMAIL_PLUGINS_PHP}'];
\$config['skin']         = '${ROUNDCUBEMAIL_SKIN}';
\$config['zipdownload_selection'] = true;
\$config['log_driver']   = 'stdout';
\$config['session_storage'] = 'db';
${SSL_OPTS_PHP}
PHP

if [ -f /var/roundcube/config/config.inc.php.user ]; then
    echo "// ---- operator overrides ----"            >> /var/roundcube/config/config.inc.php
    sed '1{/^<?php/d}' /var/roundcube/config/config.inc.php.user >> /var/roundcube/config/config.inc.php
fi

# ---------------------------------------------------------------------------
# Runtime php-fpm override driven by env (baked pool include targets this)
# ---------------------------------------------------------------------------
: > /var/roundcube/config/phpfpm.conf.override
if [ -n "${ROUNDCUBEMAIL_UPLOAD_MAX_FILESIZE:-}" ]; then
    {
        echo "php_admin_value[upload_max_filesize]=${ROUNDCUBEMAIL_UPLOAD_MAX_FILESIZE}"
        echo "php_admin_value[post_max_size]=${ROUNDCUBEMAIL_UPLOAD_MAX_FILESIZE}"
    } >> /var/roundcube/config/phpfpm.conf.override
fi

# We generated these as root — hand them to the runtime user.
chown -R roundcube:roundcube /var/roundcube/config

# ---------------------------------------------------------------------------
# Start php-fpm in the background. Master runs as root (we are root) and
# setuids its workers down to `roundcube` per the pool's user/group.
# ---------------------------------------------------------------------------
log "Starting php-fpm ${PHPVERSION}"
"/usr/sbin/php-fpm${PHPVERSION}" \
    --fpm-config "/etc/php/${PHPVERSION}/fpm/php-fpm.conf" \
    --nodaemonize &
FPM_PID=$!

# Wait for the socket before touching the DB / serving traffic.
for _ in $(seq 1 30); do [ -S /tmp/run/php-fpm.sock ] && break; sleep 0.5; done

# Initialise / migrate the schema as the runtime user (so any cache/temp it
# writes is roundcube-owned, not root).
as_rc() { runuser -u roundcube -- env "RCUBE_CONFIG_PATH=${RCUBE_CONFIG_PATH}" "$@"; }
log "Ensuring database schema"
( cd "${INSTALLDIR}" && as_rc bin/initdb.sh --dir=SQL --create >/dev/null 2>&1 \
    || as_rc bin/updatedb.sh --dir=SQL --package=roundcube >/dev/null 2>&1 ) \
    || log "WARN: schema init/update failed — run bin/initdb.sh manually"
( cd "${INSTALLDIR}" && as_rc bin/gc.sh >/dev/null 2>&1 ) || true

if [ -n "${CLEAN_INACTIVE_USERS_DAYS:-}" ]; then
    log "Purging users inactive > ${CLEAN_INACTIVE_USERS_DAYS} days"
    ( cd "${INSTALLDIR}" && as_rc bin/deluser.sh --age="${CLEAN_INACTIVE_USERS_DAYS}" ) || true
fi

# Healthcheck heartbeat.
( while kill -0 "$FPM_PID" 2>/dev/null; do
    [ -S /tmp/run/php-fpm.sock ] && touch /tmp/healthy
    sleep 30
  done ) &

log "Starting angie on :80"
exec /usr/sbin/angie -c /etc/angie/angie.conf -g 'daemon off;'
