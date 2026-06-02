# ViMbAdmin — Debian / Angie-minimal / PHP-FPM 8.5

Hardened Docker image for the modernised **[ViMbAdmin fork](https://github.com/eilandert/ViMbAdmin)** —
the Postfix + Dovecot virtual-mailbox admin panel.

- 🐳 **Docker Hub:** <https://hub.docker.com/r/eilandert/vimbadmin>
- 🔧 **App source (fork):** <https://github.com/eilandert/ViMbAdmin>
- 📖 **Write-up / guided tour:** <https://deb.myguard.nl/2026/06/vimbadmin-postfix-dovecot-mailbox-admin-panel/>

## What's in the image

| | |
|---|---|
| Base | `eilandert/debian-base` (trixie-slim + deb.myguard.nl repo + hardening) |
| Web | `angie-minimal` — no WAF module needed; a **native positive-security vhost** only lets known methods/routes/args reach PHP |
| Runtime | `php8.5-fpm`, minimal extension set, **Snuffleupagus** + the app's audited `vimbadmin-strict` ruleset |
| Config | one file: [`angie.conf`](angie.conf) |
| Size | ~320 MB |

## Security & hardening

This image is defence-in-depth: the **application** is hardened in the fork,
the **runtime** by Snuffleupagus + the FPM pool, the **edge** by a native
positive-security Angie vhost, and the **container** by the measures below.

### Container / image

- **Read-only root filesystem** (`read_only: true`). Only the `var` + `configs`
  named volumes and three tmpfs mounts (`/run`, `/tmp`, `/var/log/php-fpm`) are
  writable. Angie temp paths + pid and the FPM master error-log are redirected
  onto tmpfs so this works.
- **Codebase is root-owned and read-only to the web/PHP users.** Only `var/`
  (cache, compiled templates, logs, brute-force state, the runtime Snuffleupagus
  ruleset) and `application/configs/` are writable, and only by the unprivileged
  `phpfpm` user. The web/PHP processes cannot modify a single line of code.
- **No baked secrets.** The `securitysalt` (encrypts 2FA secrets, seeds CSRF)
  and the Snuffleupagus `secret_key` are generated **on first boot** and
  persisted in the volumes — unique per deployment, never in an image layer.
- **All Linux capabilities dropped** (`cap_drop: ALL`) except the few FPM +
  Angie genuinely need (CHOWN, SETUID, SETGID, NET_BIND_SERVICE, and
  DAC_OVERRIDE/FOWNER for first-run volume prep); **`no-new-privileges`**.
- **Minimal attack surface.** `angie-minimal` (no modsecurity/lua/brotli),
  only the PHP extensions ViMbAdmin uses, dedicated non-login `phpfpm` user.
- **Stripped:** all apt repositories + lists (no apt at runtime), composer,
  git, build deps, docs, man pages, info, non-English locales, app docs/tests,
  vendor docs/tests; every **setuid/setgid bit removed**.
- **Per-service resource limits** (memory, pids) and a healthcheck.
- **Composer installer is checksum-verified** at build (SHA-384 vs the
  published signature).

### Edge (Angie — all in [`angie.conf`](angie.conf))

- **Positive-security gate** — only allow-listed HTTP methods (GET/HEAD/POST),
  the real route map (controllers + ZF1 `/key/value` URLs + static + ACME), and
  the app's known argument names reach PHP. Unknown method → 405, route → 404,
  arg → 403; scanner / empty user-agents → dropped (444).
- **TLS-ready** strict **CSP** + `X-Frame-Options: DENY`, `nosniff`,
  Referrer-/Permissions-Policy; **rate-limited** login; dotfile + project-
  internal path denies; **BREACH mitigation** (gzip off for dynamic HTML,
  static assets only).

### Runtime + application

Provided by the fork and wired into this image:

- **Snuffleupagus** with the audited `vimbadmin-strict` ruleset (unique
  `secret_key` per deployment), and a **hardened PHP-FPM pool**
  (`open_basedir`, strict session cookies, `.php`-only execution).
- **App-level:** 2FA (TOTP, encrypted secrets, backup codes, replay guard,
  force-on-login), per-IP brute-force lockout, CSRF on every form + destructive
  link, Smarty XSS auto-escaping, constant-time password checks, CSPRNG tokens,
  session-fixation regeneration.
- Full list: the **fork's [Security section](https://github.com/eilandert/ViMbAdmin#security)**.

## Deploy

```sh
# 1. Grab the compose file (or this directory) and EDIT THE PASSWORDS.
curl -fsSLO https://raw.githubusercontent.com/eilandert/dockerized/master/src/vimbadmin/docker-compose.yml
$EDITOR docker-compose.yml          # change MARIADB_* passwords

# 2. Up.
docker compose up -d

# 3. Browse http://localhost:8080/  -> first-run super-admin setup.
#    The username is an EMAIL address (you@yourdomain), not "admin".
```

Run it behind TLS in production (terminate at your edge proxy and forward the
real client IP as `REMOTE_ADDR`, or the brute-force limiter + logs will see the
proxy). The image listens on **:80** only.

### Wire it to Postfix + Dovecot

ViMbAdmin only maintains the SQL user database — it never talks to Postfix or
Dovecot directly. Both read the **same MariaDB** through their own SQL maps;
they can live on a different host or container entirely. The Postfix
`virtual_*` maps, Dovecot `sql.conf` and the schema are in
[`EXAMPLES/`](EXAMPLES/). Let Dovecot create maildirs on first delivery/login
(`mail_location` + LMTP/LDA); this image neither sees nor needs them.

> **Password scheme must match.** ViMbAdmin hashes passwords on write; set
> Dovecot's `default_pass_scheme` to the same scheme or logins fail.

### Archive / quota / disk-delete — run on the mail host

This image is **DB-only and minimal**: no maildir mount, no `tar`/`bzip2`. The
ViMbAdmin features that touch the mail filesystem — **archive** (the
`archive.cli-*-pendings` queue), **mailbox size/quota** (`mailbox.cli-get-sizes`)
and on-disk mailbox deletion — must run **where the maildirs live**, i.e. on the
Dovecot host (or a sidecar that bind-mounts the mail volume), pointed at the
same MariaDB.

The web panel works regardless: the "Archive" button just queues a DB row. If
no filesystem cron processes that queue, rows sit at `PENDING_ARCHIVE` and
nothing is ever tarred. Example mail-host scripts + crontab live in the fork:
[`contrib/cron/`](https://github.com/eilandert/ViMbAdmin/tree/master/contrib/cron)
(`vimbadmin-archive.sh`, `vimbadmin-sizes.sh`, `crontab.example`) — each with
its requirements documented inline. If you don't use archiving, ignore them —
the feature degrades to a DB-only delete.

### Persisted state

Two named volumes hold everything that must survive a redeploy:

| Volume | Mount | Holds |
|---|---|---|
| `conf` | `/opt/vimbadmin/application/configs` | `application.ini` incl. the generated `securitysalt` |
| `var`  | `/opt/vimbadmin/var` | Smarty cache, logs, brute-force state, runtime Snuffleupagus ruleset (with secret_key) |

Back these up. Losing `conf` rotates the salt (invalidates stored 2FA secrets).

### Editing the config

The image ships its config defaults inside the image (`configs.orig`); the live
`application/configs` dir is a **mountable volume** so you can adjust
`application.ini` without rebuilding. On every start the entrypoint:

- **No `application.ini` yet** (first run / fresh volume) → seeds the whole
  config dir from the shipped defaults and generates the `securitysalt`.
- **`application.ini` present** (your config) → leaves it **untouched**, and
  drops the latest shipped default beside it as **`application.ini.orig`** so
  you can `diff` after an image bump and pull in any new keys yourself.

```sh
# inspect what changed in the shipped default after an upgrade
docker compose exec vimbadmin \
  diff -u /opt/vimbadmin/application/configs/application.ini.orig \
          /opt/vimbadmin/application/configs/application.ini
```

Your edits survive restarts and image upgrades; the image never overwrites a
config it didn't create.

### Tunables

Skin, footer toggle, brute-force thresholds + IP allowlist, 2FA reset and the
TLS/proxy notes are all documented in the fork's `application.ini.dist`.
2FA reset from the CLI:

```sh
docker compose exec vimbadmin \
  php /opt/vimbadmin/bin/vimbtool.php -a admin.cli-reset-totp --username=you@example.com
```

## Build

```sh
docker buildx bake -f docker-bake.hcl debian-vimbadmin
```
