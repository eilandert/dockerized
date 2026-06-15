#!/bin/bash
# =============================================================================
# Roundcube container entrypoint.
#
# Runs UNPRIVILEGED (compose user: roundcube, cap_drop ALL + no-new-privileges,
# read-only rootfs, angie on :8080). PID1 (bootstrap -> fpm master + angie
# master) is the roundcube uid; angie binds :8080 (>=1024, no
# CAP_NET_BIND_SERVICE), no runtime setuid/chown -> ZERO capabilities required.
#
# Because the container has NO root and CANNOT chown, every writable mount must
# already be owned by the roundcube uid (10001). Named volumes inherit the
# image dir's owner automatically; for host bind mounts / tmpfs set the owner
# yourself (host: chown -R 10001:10001 <dir>; tmpfs: uid=10001,gid=10001).
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
log "Image src: https://github.com/eilandert/dockerized/tree/master/src/roundcube"
log "Docker Hub: https://hub.docker.com/r/eilandert/roundcube"
log "Write-up  : https://deb.myguard.nl/2026/06/hardened-roundcube-docker-image/"
log "---------------------------------------------------------------------------"
log "Security profile: runs UNPRIVILEGED (no root), cap_drop ALL +"
log "  no-new-privileges + AppArmor, read-only rootfs, Angie on :8080."
log "Because the container has NO root and CANNOT chown, every WRITABLE mount"
log "  must already be owned by uid 10001 (roundcube) on the host:"
log "    named volume : nothing to do (inherits the image dir owner)"
log "    host bind dir : sudo chown -R 10001:10001 <your bind dir>"
log "    tmpfs        : --tmpfs /tmp:uid=10001,gid=10001,mode=1770"
log "  A 'Permission denied' on boot = a writable mount not owned 10001:10001."
log "---------------------------------------------------------------------------"

# ---------------------------------------------------------------------------
# Writable runtime dirs (all under the /tmp tmpfs or the config/db volumes)
# ---------------------------------------------------------------------------
: "${ROUNDCUBEMAIL_TEMP_DIR:=/tmp/roundcube-temp}"

# We run UNPRIVILEGED as roundcube and CANNOT chown. We only create subdirs
# here -- as their owner -- so no CHOWN/DAC_OVERRIDE is needed. The writable
# mounts (/var/roundcube/config, /tmp) MUST already be owned by the roundcube
# uid (named volumes inherit it; pre-chown bind mounts / tmpfs to 10001:10001).
mkdir -p /tmp/run \
         /tmp/angie/client-body /tmp/angie/proxy /tmp/angie/fastcgi \
         "${ROUNDCUBEMAIL_TEMP_DIR}" /var/roundcube/config

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
\$config['plugins']      = getenv('RCUBE_NO_PLUGINS') === '1' ? [] : ['${ROUNDCUBEMAIL_PLUGINS_PHP}'];
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

# ---------------------------------------------------------------------------
# Start php-fpm in the background. The master runs unprivileged (we ARE
# roundcube); workers inherit our identity -- no setuid (pool user/group are
# commented out, as a non-root master cannot setuid).
# ---------------------------------------------------------------------------
log "Starting php-fpm ${PHPVERSION}"
"/usr/sbin/php-fpm${PHPVERSION}" \
    --fpm-config "/etc/php/${PHPVERSION}/fpm/php-fpm.conf" \
    --nodaemonize &
FPM_PID=$!

# Wait for the socket before touching the DB / serving traffic.
for _ in $(seq 1 30); do [ -S /tmp/run/php-fpm.sock ] && break; sleep 0.5; done

# Initialise / migrate the schema. We already run as roundcube, so just call
# the CLI scripts directly (RCUBE_CONFIG_PATH is exported above).
#
# Why this is more than `initdb || updatedb`: that chain MASKS failures. On a
# fresh MariaDB the TCP port opens BEFORE the database/user are ready, so the
# old code's `initdb` failed, the `|| updatedb` "succeeded" on the empty DB
# WITHOUT creating the base tables (db_update assumes a baseline version and
# only applies deltas), the outer `|| log WARN` never fired, and both legs were
# `>/dev/null 2>&1` — net result: no tables, no warning, broken forever
# (github.com/eilandert/dockerized#81). Roundcube's CLI tools also only accept
# `initdb.sh --dir[/--update]` (NO --create/--package) and `updatedb.sh --dir
# --package`; the previous `initdb.sh --dir=SQL --create` silently dropped the
# bogus flag and always ran the DESTRUCTIVE db_init().
#
# So: probe through Roundcube's own DB layer (real readiness, driver-agnostic),
# run the destructive initial-create ONLY when the schema is genuinely absent,
# migrate otherwise, and LOG the output instead of discarding it.
as_rc() { "$@"; }

# Run every CLI bootstrap step (schema probes, initdb, updatedb, gc, deluser)
# with plugins DISABLED. Roundcube's `clisetup.php` instantiates rcmail, which
# loads and init()s every enabled plugin — and request-time plugins are not
# CLI-safe: e.g. identity_switch's init() calls get_cfg(0, $user->get_identity()
# ['email']) and there is NO logged-in user in CLI, so $email is null and its
# `string $email` type hint throws a fatal TypeError that aborts the schema step
# (github.com/eilandert/dockerized#81). Plugin SQL is applied via initdb/updatedb
# `--dir`, which does NOT need the plugin's PHP loaded, so disabling plugins here
# is safe and correct. config.inc.php reads this env (getenv) — php-fpm started
# earlier without it, so web requests still load the full plugin set.
export RCUBE_NO_PLUGINS=1

case "${ROUNDCUBEMAIL_DB_TYPE}" in
    pgsql) db_driver_file="postgres" ;;
    *)     db_driver_file="mysql" ;;
esac

# rc_core_state: 0 = DB up AND core schema present, 1 = DB up but no schema,
# 2 = DB unreachable. Uses Roundcube's configured DSN (handles mysql + pgsql).
rc_core_state() {
    ( cd "${INSTALLDIR}" && php -d error_reporting=0 -r '
        define("INSTALL_PATH", getcwd()."/");
        require_once INSTALL_PATH."program/include/clisetup.php";
        $db = rcube::get_instance()->get_dbh();
        $db->db_connect("w");
        if (!$db->is_connected()) { exit(2); }
        $db->query("SELECT 1 FROM ".$db->table_name("session")." LIMIT 1");
        exit($db->is_error() ? 1 : 0);
    ' ) >/dev/null 2>&1
}

# rc_pkg_versioned <package>: 0 if the package already has a recorded schema
# version in the `system` table (so its initial create has run); else non-zero.
rc_pkg_versioned() {
    ( cd "${INSTALLDIR}" && php -d error_reporting=0 -r '
        define("INSTALL_PATH", getcwd()."/");
        require_once INSTALL_PATH."program/include/clisetup.php";
        $db = rcube::get_instance()->get_dbh();
        $db->db_connect("w");
        if (!$db->is_connected()) { exit(2); }
        $r = $db->query("SELECT value FROM ".$db->table_name("system")." WHERE name=?", $argv[1]."-version");
        if ($db->is_error()) { exit(1); }
        exit($db->fetch_assoc($r) ? 0 : 1);
    ' "$1" ) >/dev/null 2>&1
}

# rc_set_pkg_version <package> <version>: stamp the `system` table so a plugin
# whose initial.sql does not self-register a version is still recorded as
# installed — otherwise a reboot would re-run the DESTRUCTIVE initial create.
rc_set_pkg_version() {
    ( cd "${INSTALLDIR}" && php -d error_reporting=0 -r '
        define("INSTALL_PATH", getcwd()."/");
        require_once INSTALL_PATH."program/include/clisetup.php";
        $db = rcube::get_instance()->get_dbh();
        $db->db_connect("w");
        if (!$db->is_connected()) { exit(1); }
        $t = $db->table_name("system");
        $db->query("DELETE FROM $t WHERE name=?", $argv[1]."-version");
        $db->query("INSERT INTO $t (name, value) VALUES (?, ?)", $argv[1]."-version", $argv[2]);
        exit($db->is_error() ? 1 : 0);
    ' "$1" "$2" ) >/dev/null 2>&1
}

# Wait until the database is genuinely reachable — not just the TCP port, which
# wait-for-it already checked. Up to ~60s; proceed either way but log loudly.
log "Waiting for database to become ready"
db_ready=0
for _ in $(seq 1 60); do
    st=0; rc_core_state || st=$?
    if [ "$st" != 2 ]; then db_ready=1; break; fi
    sleep 1
done
[ "$db_ready" = 1 ] || log "WARN: database still unreachable after 60s — schema step may fail"

# --- Core schema: create when absent, migrate when present (output LOGGED) ---
st=0; rc_core_state || st=$?
case "$st" in
    1)
        log "Core schema absent — initialising (bin/initdb.sh --dir=SQL)"
        if ! ( cd "${INSTALLDIR}" && as_rc bin/initdb.sh --dir=SQL ) 2>&1 \
                | sed 's/^/[ROUNDCUBE][initdb] /'; then
            log "ERROR: core schema init FAILED — Roundcube will not work until 'bin/initdb.sh --dir=SQL' succeeds"
        fi
        ;;
    0)
        log "Core schema present — applying migrations (bin/updatedb.sh)"
        ( cd "${INSTALLDIR}" && as_rc bin/updatedb.sh --dir=SQL --package=roundcube ) 2>&1 \
            | sed 's/^/[ROUNDCUBE][updatedb] /' || true
        ;;
    *)
        log "ERROR: database unreachable — SKIPPING schema step (no tables will be created)"
        ;;
esac

# --- Enabled-plugin schemas ----------------------------------------------------
# Roundcube core init does NOT migrate third-party plugin tables. For every
# enabled plugin that ships SQL/<driver>.initial.sql we create-on-first-boot
# (initdb on the plugin dir + stamp the version so it is never re-dropped) and
# migrate thereafter. Set ROUNDCUBEMAIL_PLUGIN_DB_INIT=0 to opt out entirely.
if [ "$st" != 2 ] && [ "${ROUNDCUBEMAIL_PLUGIN_DB_INIT:-1}" != "0" ]; then
    IFS=',' read -ra _plugins <<< "${ROUNDCUBEMAIL_PLUGINS}"
    for _p in "${_plugins[@]}"; do
        _p="$(echo "$_p" | tr -d '[:space:]')"
        [ -n "$_p" ] || continue
        _sqldir="${INSTALLDIR}/plugins/${_p}/SQL"
        [ -f "${_sqldir}/${db_driver_file}.initial.sql" ] || continue
        if rc_pkg_versioned "$_p"; then
            log "Plugin '${_p}': schema present — migrating"
            ( cd "${INSTALLDIR}" && as_rc bin/updatedb.sh --dir="plugins/${_p}/SQL" --package="${_p}" ) 2>&1 \
                | sed "s/^/[ROUNDCUBE][${_p}] /" || true
        else
            log "Plugin '${_p}': schema absent — initialising"
            if ( cd "${INSTALLDIR}" && as_rc bin/initdb.sh --dir="plugins/${_p}/SQL" ) 2>&1 \
                    | sed "s/^/[ROUNDCUBE][${_p}] /"; then
                # The initial.sql reflects the latest schema; stamp the newest
                # delta version (or 0) so updatedb does not re-apply deltas.
                _ver="$(ls "${_sqldir}/${db_driver_file}/" 2>/dev/null | sed -n 's/\.sql$//p' | sort -n | tail -1)"
                rc_set_pkg_version "$_p" "${_ver:-0}" \
                    || log "WARN: plugin '${_p}' schema created but version stamp failed (reboot may re-init)"
            else
                log "ERROR: plugin '${_p}' schema init FAILED — see [${_p}] lines above"
            fi
        fi
    done
fi
( cd "${INSTALLDIR}" && as_rc bin/gc.sh >/dev/null 2>&1 ) || true

if [ -n "${CLEAN_INACTIVE_USERS_DAYS:-}" ]; then
    log "Purging users inactive > ${CLEAN_INACTIVE_USERS_DAYS} days"
    # deluser.sh has an upstream PHP 8.x notice ("Undefined array key host")
    # when invoked without --host; the purge still works. Drop stderr so the
    # cosmetic notice doesn't spam the container log; keep the deleted list.
    ( cd "${INSTALLDIR}" && as_rc bin/deluser.sh --age="${CLEAN_INACTIVE_USERS_DAYS}" 2>/dev/null ) || true
fi

# Healthcheck heartbeat.
( while kill -0 "$FPM_PID" 2>/dev/null; do
    [ -S /tmp/run/php-fpm.sock ] && touch /tmp/healthy
    sleep 30
  done ) &

log "Starting angie on :8080"
exec /usr/sbin/angie -c /etc/angie/angie.conf -g 'daemon off;'
