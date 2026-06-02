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

### Hardening

- **Read-only root filesystem** (`read_only: true`). Only the `var` + `configs`
  volumes and a few tmpfs mounts are writable.
- **Codebase is root-owned, read-only to the web/PHP users.** Only
  `var/` (cache, compiled templates, logs, brute-force state, the runtime
  Snuffleupagus ruleset) and `application/configs/` are writable, and only by
  the `phpfpm` user.
- **Per-deployment secrets generated on first run** — the `securitysalt`
  (encrypts 2FA secrets, seeds CSRF) and the Snuffleupagus `secret_key` are
  created on first boot and persisted in the volumes; **nothing secret is
  baked into the image**.
- **All Linux capabilities dropped** except the few FPM/Angie need; `no-new-privileges`.
- Docs, man pages, locales, apt repositories, composer and git are removed;
  setuid/setgid bits stripped.

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

ViMbAdmin only maintains the SQL user database. The Postfix `virtual_*` maps,
Dovecot `sql.conf` and the schema are in [`EXAMPLES/`](EXAMPLES/).

### Persisted state

Two named volumes hold everything that must survive a redeploy:

| Volume | Mount | Holds |
|---|---|---|
| `conf` | `/opt/vimbadmin/application/configs` | `application.ini` incl. the generated `securitysalt` |
| `var`  | `/opt/vimbadmin/var` | Smarty cache, logs, brute-force state, runtime Snuffleupagus ruleset (with secret_key) |

Back these up. Losing `conf` rotates the salt (invalidates stored 2FA secrets).

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
