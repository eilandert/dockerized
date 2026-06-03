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
file below bundles a hardened MariaDB; point `ROUNDCUBEMAIL_DEFAULT_HOST` /
`ROUNDCUBEMAIL_SMTP_SERVER` at your own IMAP/SMTP servers. Run it behind TLS in
production (terminate at your edge proxy, forward the real client IP via
`X-Forwarded-For` so the brute-force throttle keys on the actual client). The
container listens on **:8080** only.

### `docker-compose.yml`

```yaml
services:
  db:
    image: docker.io/eilandert/mariadb:debian
    restart: unless-stopped
    environment:
      MARIADB_DATABASE: roundcube
      MARIADB_USER: roundcube
      MARIADB_PASSWORD: change-me
      MARIADB_ROOT_PASSWORD: change-me-too
    volumes:
      - db:/var/lib/mysql
    networks: [rc]
    security_opt:
      - no-new-privileges:true
    cap_drop: [ALL]
    cap_add: [CHOWN, SETUID, SETGID, DAC_OVERRIDE]
    deploy:
      resources:
        limits:
          memory: 512M
          pids: 256
    healthcheck:
      test: ["CMD", "healthcheck.sh", "--connect", "--innodb_initialized"]
      interval: 10s
      timeout: 5s
      retries: 12

  roundcube:
    image: docker.io/eilandert/roundcube:latest
    restart: unless-stopped
    depends_on:
      db:
        condition: service_healthy
    # Unprivileged: cap_drop ALL -> the container CANNOT chown, so the config
    # mount must already be owned 10001:10001 (a named volume inherits it).
    user: "10001:10001"
    environment:
      TZ: Europe/Amsterdam
      # ---- IMAP (reading mail) ----
      ROUNDCUBEMAIL_DEFAULT_HOST: ssl://imap.example.org
      ROUNDCUBEMAIL_DEFAULT_PORT: 993
      # ---- SMTP (sending mail) ----
      ROUNDCUBEMAIL_SMTP_SERVER: tls://smtp.example.org
      ROUNDCUBEMAIL_SMTP_PORT: 587
      # TLS to your mail server is VERIFIED by default. If the cert won't match:
      #   pin a CA: ROUNDCUBEMAIL_SSL_CA=/etc/ssl/mail-ca.pem (mount it :ro)
      #   trusted LAN only (allows MITM): ROUNDCUBEMAIL_SSL_VERIFY: 0
      # ---- database (points at the bundled `db` service) ----
      ROUNDCUBEMAIL_DB_TYPE: mysql
      ROUNDCUBEMAIL_DB_HOST: db
      ROUNDCUBEMAIL_DB_PORT: 3306
      ROUNDCUBEMAIL_DB_USER: roundcube
      ROUNDCUBEMAIL_DB_PASSWORD: change-me      # must match MARIADB_PASSWORD
      ROUNDCUBEMAIL_DB_NAME: roundcube
      # ---- app ----
      ROUNDCUBEMAIL_PLUGINS: archive,zipdownload,managesieve,newmail_notifier,password,new_user_dialog,contextmenu,persistent_login
      ROUNDCUBEMAIL_UPLOAD_MAX_FILESIZE: 25M
      ROUNDCUBEMAIL_SKIN: elastic
      CLEAN_INACTIVE_USERS_DAYS: 365
    ports:
      - "8080:8080"        # terminate TLS upstream in production
    networks: [rc]
    # ---- hardening ----
    read_only: true        # rootfs is immutable; writes go to the mounts below
    volumes:
      - conf:/var/roundcube/config
    tmpfs:
      - /tmp:uid=10001,gid=10001,mode=1770
    security_opt:
      - no-new-privileges:true
      - apparmor=docker-default
    cap_drop: [ALL]        # angie binds :8080 -> ZERO capabilities required
    ulimits:
      nofile:
        soft: 10240
        hard: 10240
    deploy:
      resources:
        limits:
          memory: 512M
          pids: 256
    logging:
      driver: json-file
      options:
        max-size: "10m"
        max-file: "3"

networks:
  rc:

volumes:
  db:
  conf:
```

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

## Bundled plugins & skins

The image ships these pre-installed; enable the ones you want with
`ROUNDCUBEMAIL_PLUGINS` (comma-separated). Nothing is loaded unless you list it.

### Plugins

| Plugin | Version | What it does |
|---|---|---|
| `contextmenu` | 3.3.1 | Right-click context menus on the message list / folders |
| `contextmenu_folder` | 2.0.2 | Folder management context menu (create/rename/move) |
| `swipe` | 0.6 | Touch swipe gestures (mobile) |
| `show_folder_size` | 0.7.22 | Folder size column in the folder manager |
| `quota` | git | Mailbox quota display / IMAP quota support |
| `persistent_login` | 1.0.3 | "Keep me logged in" persistent sessions |
| `advanced_search` | 3.7 | Extended search form (date ranges, flags, headers) |
| `account_details` | 5.0.0 | Per-account info pane |
| `message_highlight` | 1.0.5 | Colour-highlight messages by rule |
| `authres` (authres_status) | 0.7.1 | Show SPF/DKIM/DMARC authentication results |
| `thunderbird_labels` | 1.6.2 | Thunderbird-compatible coloured labels/tags |
| `responses` | 1.3.13 | Canned-response templates |
| `easy_unsubscribe` | git | One-click List-Unsubscribe button |
| `rcguard` | 1.3.2 | reCAPTCHA after failed logins (extra brute-force defence) |
| `kolab_2fa` | composer | Two-factor auth (TOTP / Yubikey / U2F) |
| `carddav` | composer | CardDAV address-book sync |

2FA support libraries (`endroid/qr-code`, `spomky-labs/otphp`,
`enygma/yubikey`) are bundled for `kolab_2fa`. Roundcube core plugins
(`archive`, `zipdownload`, `managesieve`, `newmail_notifier`, `password`,
`new_user_dialog`) ship with Roundcube itself and are enabled in the default
`ROUNDCUBEMAIL_PLUGINS`.

### Skins

Set one with `ROUNDCUBEMAIL_SKIN` (default `elastic`).

| Skin | Source | Notes |
|---|---|---|
| `elastic` | Roundcube core | Default, responsive |
| `elastic4mobile` | roundcube/elastic4mobile | Mobile-tuned elastic variant |
| `elastic-dark` | tborychowski/elastic-dark | Dark theme (extends elastic) |
| `elastic2025` | bijanbina/Elastic2025 | Refreshed elastic look |
| `gmail` | bundled (this image) | Gmail look-alike (extends elastic) |
| `outlook365` | bundled (this image) | Outlook 365 look-alike (extends elastic) |
| `larry` | roundcube/larry | The classic RC 1.x skin |
| `classic` | roundcube/classic | Minimal classic skin |

## Configuration

Everything is driven by `ROUNDCUBEMAIL_*` environment variables (IMAP/SMTP
hosts + ports, DB DSN, plugin list, skin, upload size, TLS verification mode).
For per-deployment PHP overrides drop a `phpfpm.conf.override` in the config
volume; for extra Roundcube config drop a `config.inc.php.user`. TLS to your
mail server is **verified by default** — set `ROUNDCUBEMAIL_SSL_CA` to pin a
private CA, or (trusted LAN only, allows MITM) `ROUNDCUBEMAIL_SSL_VERIFY=0`.

Full env reference, plugin list, custom skins and tunables: **see the
[README](https://github.com/eilandert/dockerized/tree/master/src/roundcube).**
