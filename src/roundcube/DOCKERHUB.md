# Roundcube — hardened Debian / Angie-minimal / PHP-FPM 8.5

A small, **fully-unprivileged**, defence-in-depth Docker image for
**[Roundcube](https://roundcube.net/)** webmail — the browser interface that
turns a raw IMAP mailbox into a clean, fast, plugin-extensible inbox.

## Links

- 📦 **Image source / full README:** <https://github.com/eilandert/dockerized/tree/master/src/roundcube>
- 🔧 **App source (upstream):** <https://github.com/roundcube/roundcubemail>
- 📖 **Write-up / guided tour:** <https://deb.myguard.nl/2026/06/hardened-roundcube-docker-image/>

## Tags

| Tag | What |
|---|---|
| `latest`, `debian` | Debian trixie · Angie-minimal · PHP-FPM 8.5 (amd64) |

## Why this image

Roundcube is a PHP application sitting directly between the public internet and
your users' email — one of the highest-value targets you can self-host. Most
webmail images run a web server + PHP as root with a fat capability set. This
one doesn't run root **anywhere** and holds **zero Linux capabilities**.

### Security highlights

- **No root, anywhere.** PID 1, every Angie worker and the whole PHP-FPM tree
  run as the unprivileged `roundcube` user (`user: "10001:10001"`).
- **Zero capabilities** — `cap_drop: [ALL]`, **no `cap_add`**. Angie binds a
  high port (**:8080**) so it needs no `CAP_NET_BIND_SERVICE`; nothing does
  runtime `setuid`/`chown`.
- **`no-new-privileges`** + **AppArmor** (`docker-default`).
- **Read-only root filesystem.** Only the config volume + the `/tmp` tmpfs are
  writable; the application code is immutable to the web/PHP user.
- **No baked secrets** — the Roundcube `des_key` is generated on first boot,
  unique per deployment, never in an image layer.
- **Snuffleupagus** loaded with a strict, source-audited Roundcube rulebook, on
  a **hardened PHP-FPM pool**: `open_basedir`, `expose_php` off,
  `allow_url_fopen`/`allow_url_include` off, a wide `disable_functions`
  (exec/system/proc_open/… all gone), and `Secure`+`HttpOnly`+`SameSite=Strict`
  session cookies with 64-char IDs.
- **Angie WAF at the front:** **gzip off** (kills the [BREACH](https://deb.myguard.nl/2026/05/breach-attack-explained-prevention/)
  side-channel on CSRF-bearing HTML), `real_ip` from the trusted proxy,
  scanner / empty-UA requests dropped (`444`), login brute-force throttle
  (`limit_req`, real-client-keyed, login-only), plus **CSP** and **HSTS**.
- **PHP execution allow-list** — only `index.php` and `static.php` ever run; any
  other dropped/uploaded `.php` returns 404.
- **Minimal surface / stripped:** `angie-minimal` (no modsecurity/lua/brotli),
  only the PHP extensions Roundcube uses, no apt/composer/git at runtime, no
  docs/man/locales, every setuid/setgid bit removed.
- Resource limits (memory, pids, nofile) + a self-contained healthcheck.

## Quick start

```sh
# Grab the compose file and CHANGE THE PASSWORDS + mail servers first.
curl -fsSLO https://raw.githubusercontent.com/eilandert/dockerized/master/src/roundcube/docker-compose.yml
$EDITOR docker-compose.yml     # set MARIADB_* + ROUNDCUBEMAIL_DB_PASSWORD,
                               # and ROUNDCUBEMAIL_DEFAULT_HOST / SMTP_SERVER
docker compose up -d
# Browse http://localhost:8080/  ->  log in with an IMAP account.
```

An external database is **mandatory** (there is no SQLite fallback). The compose
file above bundles a hardened MariaDB; point `ROUNDCUBEMAIL_DEFAULT_HOST` /
`ROUNDCUBEMAIL_SMTP_SERVER` at your own IMAP/SMTP servers. Run it behind TLS in
production (terminate at your edge proxy, forward the real client IP via
`X-Forwarded-For` so the brute-force throttle keys on the actual client). The
container listens on **:8080** only.

## ⚠️ Mount ownership (because the container can't chown)

With `cap_drop: [ALL]` the container **cannot** change file ownership, so any
**writable** mount must already be owned by the runtime user **uid `10001`
(`roundcube`)**:

- **Named volumes** (compose default) — nothing to do, they inherit it.
- **Host bind mounts** — pre-own once:
  ```sh
  sudo chown -R 10001:10001 /your/bind/dir
  ```
- **tmpfs** — set it in the mount options:
  ```yaml
  tmpfs:
    - /tmp:uid=10001,gid=10001,mode=1770
  ```

A *Permission denied* on boot means a writable mount isn't owned `10001:10001`.
The fix is always the `chown` above — never add a capability back. (The
container prints these same instructions in its startup logs.)

## Configuration

Everything is driven by `ROUNDCUBEMAIL_*` environment variables (IMAP/SMTP
hosts + ports, DB DSN, plugin list, skin, upload size, TLS verification mode).
For per-deployment PHP overrides drop a `phpfpm.conf.override` in the config
volume; for extra Roundcube config drop a `config.inc.php.user`. TLS to your
mail server is **verified by default** — set `ROUNDCUBEMAIL_SSL_CA` to pin a
private CA, or (trusted LAN only, allows MITM) `ROUNDCUBEMAIL_SSL_VERIFY=0`.

Full env reference, plugin list, custom skins and tunables: **see the
[README](https://github.com/eilandert/dockerized/tree/master/src/roundcube).**
