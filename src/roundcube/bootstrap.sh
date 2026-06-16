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
#
# Writable-mount probe: the banner above *explains* this requirement; here we
# actually TEST it. A wrong-owner bind mount / tmpfs otherwise surfaces as a
# cryptic "mkdir: Permission denied" (or a failed config write) under set -e and
# the container just exits. Probe the writable ROOTS (mount points, not every
# leaf) and emit a clear, actionable warning naming the path + the chown fix.
RC_UID="$(id -u)"
for _w in /var/roundcube/config /tmp "${ROUNDCUBEMAIL_TEMP_DIR}"; do
    [ -d "$_w" ] || continue
    _probe="${_w}/.rc-write-test.$$"
    if touch "$_probe" 2>/dev/null; then
        rm -f "$_probe"
    else
        log "WARNING: '${_w}' is NOT writable by uid ${RC_UID} (roundcube)."
        log "  Host bind dir : sudo chown -R 10001:10001 <that dir>"
        log "  tmpfs mount   : --tmpfs ${_w}:uid=10001,gid=10001,mode=1770"
        log "  Roundcube will fail to start until this mount is writable."
    fi
done

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
# des_key MUST stay stable across restarts: Roundcube encrypts the IMAP
# password into the (DB-backed) session with it. A fresh key on every boot makes
# every pre-existing session undecryptable -> "Server Error: Empty password" /
# "Connection to storage server failed" after `docker compose restart`.
# Resolution order:
#   1. Docker secret  /run/secrets/roundcube_des_key   (explicit, best)
#   2. env            ROUNDCUBEMAIL_DES_KEY            (explicit operator value)
#   3. persisted      <config>/.des_key               (generated once, reused)
#   4. generate a new 24-char key and persist it to (3)
DES_KEY_FILE=/var/roundcube/config/.des_key
if [ -f /run/secrets/roundcube_des_key ]; then
    ROUNDCUBEMAIL_DES_KEY="$(cat /run/secrets/roundcube_des_key)"
elif [ -n "${ROUNDCUBEMAIL_DES_KEY:-}" ]; then
    : # honour operator-supplied env var
elif [ -f "${DES_KEY_FILE}" ]; then
    ROUNDCUBEMAIL_DES_KEY="$(cat "${DES_KEY_FILE}")"
else
    ROUNDCUBEMAIL_DES_KEY="$(head -c 24 /dev/urandom | base64 | head -c 24)"
    ( umask 077; printf '%s' "${ROUNDCUBEMAIL_DES_KEY}" > "${DES_KEY_FILE}" )
fi

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
# Enabled-plugin presence check. An enabled plugin with no
# plugins/<p>/<p>.php makes Roundcube fatal at REQUEST time ("Failed to load
# plugin file ...") — a silent, confusing failure: the container boots, but
# every web request 500s and nothing in the boot log says why. Warn loudly at
# boot instead so a typo'd / not-bundled plugin is obvious (core plugins live at
# plugins/<p>/<p>.php too, so one check covers both core + third-party).
# github.com/eilandert/dockerized#81: identity_switch was enabled but not
# bundled in the image.
# ---------------------------------------------------------------------------
IFS=',' read -ra _enabled <<< "${ROUNDCUBEMAIL_PLUGINS}"
for _p in "${_enabled[@]}"; do
    _p="$(echo "$_p" | tr -d '[:space:]')"
    [ -n "$_p" ] || continue
    [ -f "${INSTALLDIR}/plugins/${_p}/${_p}.php" ] && continue
    log "WARNING: plugin '${_p}' is enabled but NOT installed in this image"
    log "  (missing ${INSTALLDIR}/plugins/${_p}/${_p}.php) — Roundcube will 500 on"
    log "  every request. Remove it from ROUNDCUBEMAIL_PLUGINS, mount it into"
    log "  plugins/${_p}/, or use an image that bundles it."
done

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

# rc_obj_exists <table> [column]: 0 = DB up AND the object exists (the table, or
# the given column on that table), 1 = DB up but object absent, 2 = DB
# unreachable. Driver-agnostic (mysql + pgsql). This ACTUAL-schema signal (not a
# recorded version) is what lets the schema steps self-heal partial states.
rc_obj_exists() {
    ( cd "${INSTALLDIR}" && php -d error_reporting=0 -r '
        define("INSTALL_PATH", getcwd()."/");
        require_once INSTALL_PATH."program/include/clisetup.php";
        $db = rcube::get_instance()->get_dbh();
        $db->db_connect("w");
        if (!$db->is_connected()) { exit(2); }
        $col = (isset($argv[2]) && $argv[2] !== "") ? $db->quote_identifier($argv[2]) : "1";
        $db->query("SELECT $col FROM ".$db->table_name($argv[1])." LIMIT 1");
        exit($db->is_error() ? 1 : 0);
    ' "$1" "${2:-}" ) >/dev/null 2>&1
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
    st=0; rc_obj_exists session || st=$?
    if [ "$st" != 2 ]; then db_ready=1; break; fi
    sleep 1
done
[ "$db_ready" = 1 ] || log "WARN: database still unreachable after 60s — schema step may fail"

# --- Core schema: create when absent, migrate when present (output LOGGED) ---
st=0; rc_obj_exists session || st=$?
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

# --- Enabled-plugin schemas (self-healing) -------------------------------------
# Roundcube core init does NOT migrate third-party plugin tables. For every
# enabled plugin shipping SQL/<driver>.initial.sql we reconcile the ACTUAL
# schema against the recorded version, so a partial/aborted previous run repairs
# itself instead of looping or destroying data. The schema marker is the first
# object the initial.sql establishes — a CREATE TABLE, or (for ALTER-only
# plugins like identity_switch, whose real schema is just an added column) an
# ALTER TABLE ... ADD <column>:
#   marker present + version   -> migrate (updatedb)
#   marker present, no version -> record version only — NEVER re-run initdb,
#                                 which would DROP a table / duplicate-ADD a column
#   marker absent              -> (re)create (initdb) + stamp (clears stale version)
# Plugin SQL is applied via --dir; the plugin's PHP is not loaded (RCUBE_NO_PLUGINS).
# Set ROUNDCUBEMAIL_PLUGIN_DB_INIT=0 to opt out entirely.
if [ "$st" != 2 ] && [ "${ROUNDCUBEMAIL_PLUGIN_DB_INIT:-1}" != "0" ]; then
    IFS=',' read -ra _plugins <<< "${ROUNDCUBEMAIL_PLUGINS}"
    for _p in "${_plugins[@]}"; do
        _p="$(echo "$_p" | tr -d '[:space:]')"
        [ -n "$_p" ] || continue
        _sqldir="${INSTALLDIR}/plugins/${_p}/SQL"
        _initial="${_sqldir}/${db_driver_file}.initial.sql"
        [ -f "$_initial" ] || continue

        # newest delta version = what a fresh initial.sql already corresponds to.
        # The SQL/<driver>/ delta dir is OPTIONAL: a plugin may ship only
        # <driver>.initial.sql with no deltas (e.g. persistent_login). Guard the
        # ls — on a missing dir it exits 2, which `set -o pipefail` turns into a
        # non-zero pipeline -> the `_ver=$(...)` assignment exits non-zero ->
        # `set -e` kills PID1 and the container restart-loops, silently, before
        # any per-plugin log line (github.com/eilandert/dockerized#81).
        _ver=""
        [ -d "${_sqldir}/${db_driver_file}" ] && \
            _ver="$(ls "${_sqldir}/${db_driver_file}/" 2>/dev/null | sed -n 's/\.sql$//p' | sort -n | tail -1)"

        # schema marker: a created table, else an added column (table + column)
        _mtable="$(sed -n -E 's/.*CREATE TABLE([[:space:]]+IF NOT EXISTS)?[[:space:]]+`?([A-Za-z0-9_]+)`?.*/\2/Ip' "$_initial" | head -1)"
        _mcol=""
        if [ -z "$_mtable" ]; then
            _alter="$(sed -n -E 's/.*ALTER TABLE[[:space:]]+`?([A-Za-z0-9_]+)`?[[:space:]]+ADD[[:space:]]+(COLUMN[[:space:]]+)?`?([A-Za-z0-9_]+)`?.*/\1 \3/Ip' "$_initial" | head -1)"
            case "$_alter" in *" "*) _mtable="${_alter%% *}"; _mcol="${_alter#* }" ;; esac
        fi

        if rc_pkg_versioned "$_p"; then _has_ver=0; else _has_ver=1; fi
        if [ -n "$_mtable" ]; then
            if rc_obj_exists "$_mtable" "$_mcol"; then _has_obj=0; else _has_obj=1; fi
        else
            _has_obj=$_has_ver   # no detectable marker -> fall back to version row
        fi

        if [ "$_has_obj" = 0 ] && [ "$_has_ver" = 0 ]; then
            log "Plugin '${_p}': schema present — migrating"
            ( cd "${INSTALLDIR}" && as_rc bin/updatedb.sh --dir="plugins/${_p}/SQL" --package="${_p}" ) 2>&1 \
                | sed "s/^/[ROUNDCUBE][${_p}] /" || true
        elif [ "$_has_obj" = 0 ]; then
            log "Plugin '${_p}': schema present but unversioned — recording version (self-heal, no re-create)"
            rc_set_pkg_version "$_p" "${_ver:-0}" \
                || log "WARN: plugin '${_p}' version stamp failed"
        else
            if [ "$_has_ver" = 0 ]; then
                log "Plugin '${_p}': recorded but schema missing — re-initialising (self-heal)"
            else
                log "Plugin '${_p}': schema absent — initialising"
            fi
            if ( cd "${INSTALLDIR}" && as_rc bin/initdb.sh --dir="plugins/${_p}/SQL" ) 2>&1 \
                    | sed "s/^/[ROUNDCUBE][${_p}] /"; then
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
