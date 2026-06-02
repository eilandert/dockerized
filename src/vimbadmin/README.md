# ViMbAdmin — Debian / Angie-minimal / PHP-FPM 8.5

Docker image for the modernised
[ViMbAdmin fork](https://github.com/eilandert/ViMbAdmin) — the Postfix +
Dovecot virtual-mailbox admin panel.

- **Base:** `eilandert/debian-base` (trixie-slim + deb.myguard.nl repo + hardening)
- **Web:** `angie-minimal` — no modsecurity/lua needed; the panel is guarded by
  a native **positive-security** vhost (only known methods/routes/args reach PHP)
- **Runtime:** `php8.5-fpm` (minimal extension set) + Snuffleupagus with the
  app's audited `vimbadmin-strict` ruleset
- All Angie config is in one file: [`angie.conf`](angie.conf)
- ~320 MB

## Run

```sh
docker compose up -d        # see docker-compose.yml (bring your own passwords)
# browse http://localhost:8080/  -> first-run super-admin setup
```

Behind TLS in production. The image serves :80; terminate TLS at your edge
proxy (and map the real client IP into `REMOTE_ADDR` so the brute-force
limiter and logs are accurate).

## Wire it to Postfix + Dovecot

ViMbAdmin only maintains the SQL user database. See [`EXAMPLES/`](EXAMPLES/)
for the Postfix `virtual_*` maps, Dovecot `sql.conf` and the schema.

## Config

The container writes `application/configs/application.ini` on first run with a
`[docker]` env (random `securitysalt`, `skin = dark`). Persist
`/opt/vimbadmin/application/configs` and `/opt/vimbadmin/var` (compose does).
Tunables (2FA reset, brute-force, footer, skin) are documented in the fork's
`application.ini.dist`.

## Build

```sh
docker buildx bake -f docker-bake.hcl debian-vimbadmin
```
