# Roundcube — hardened Docker image (Debian / Angie-minimal / PHP-FPM 8.5)

A small, **fully-unprivileged**, defence-in-depth Docker image for
[Roundcube](https://roundcube.net/) webmail. PID 1 and the whole PHP/web tree
run as a non-root user (uid 10001), the container holds **zero Linux
capabilities**, the root filesystem is **read-only**, and an Angie WAF sits in
front of PHP.

## Links

- 🐳 **Docker Hub:** <https://hub.docker.com/r/eilandert/roundcube>
- 🔧 **App source (upstream):** <https://github.com/roundcube/roundcubemail>
- 📖 **Write-up / guided tour:** <https://deb.myguard.nl/2026/06/hardened-roundcube-docker-image/>

## What's in the image

| | |
|---|---|
| Base | `eilandert/debian-base:stable` (trixie + deb.myguard.nl repo + hardening) |
| Web | `angie-minimal` — single self-contained `angie.conf` with a WAF gate in front of PHP |
| Runtime | `php8.5-fpm`, minimal extension set, **Snuffleupagus** + a strict source-audited Roundcube ruleset |
| Cache | tuned **OPcache** + **APCu** |
| DB | external **MariaDB/MySQL or PostgreSQL** (mandatory; no SQLite) |
| Config | one file each: [`angie.conf`](angie.conf), [`phpfpm.conf`](phpfpm.conf), [`bootstrap.sh`](bootstrap.sh) |

## Security & hardening

Defence in depth: the **runtime** is hardened by Snuffleupagus + the FPM pool,
the **edge** by an Angie WAF, and the **container** by the measures below.

### Container / image

- **Runs fully unprivileged — no root, anywhere.** PID 1 (bootstrap → the Angie
  and PHP-FPM masters), every worker, all of it runs as the unprivileged
  `roundcube` user (`USER roundcube:roundcube` in the image; `user:
  "10001:10001"` in compose). No root process at any point.
- **Zero Linux capabilities** — `cap_drop: [ALL]` with **no `cap_add`**. Angie
  binds a high port (**:8080**, no `CAP_NET_BIND_SERVICE`); nothing does runtime
  `setuid`/`chown` (the masters are already unprivileged; writable mounts are
  pre-owned — see *Mount ownership*).
- **`no-new-privileges`** + **AppArmor** (`apparmor=docker-default`).
- **Read-only root filesystem** (`read_only: true`). Only the config volume and
  the `/tmp` tmpfs are writable; Angie's pid/sockets/temp + the FPM error log
  are redirected there so the rest of the rootfs stays immutable.
- **Codebase read-only to the web/PHP user** — owned `roundcube:roundcube`
  `0440`/`0550`. The web/PHP processes cannot modify a line of code.
- **No baked secrets** — the Roundcube `des_key` is generated on first boot,
  unique per deployment, never in an image layer.
- **Every setuid/setgid bit stripped** at build time.

### Runtime (PHP)

- **Snuffleupagus** with a strict, source-audited Roundcube rulebook (virtual
  patching, dangerous-function kills, uploaded-file no-exec, secure cookies).
- **Hardened PHP-FPM pool** (`php_admin_*`, not overridable by userland):
  `open_basedir` jail, `expose_php` off, `allow_url_fopen`/`allow_url_include`
  off, a wide `disable_functions` (exec/system/proc_open/passthru/… gone), and
  `Secure`+`HttpOnly`+`SameSite=Strict` session cookies with 64-char IDs.

### Edge (Angie WAF)

- **gzip off** — closes the [BREACH](https://deb.myguard.nl/2026/05/breach-attack-explained-prevention/)
  side-channel on CSRF-token-bearing HTML.
- **`real_ip`** from the trusted private proxy ranges (reads `X-Forwarded-For`)
  so the throttle + RC's failed-login tracking see the real client.
- **Scanner / empty-UA gate** → `return 444` (nikto/sqlmap/nmap/nuclei/wpscan/…).
- **Login brute-force throttle** (`limit_req`, 12 r/min + burst) keyed on the
  real client IP, applied to login POSTs only (an empty-key map keeps normal
  browsing through `index.php` un-throttled).
- **CSP + HSTS** response headers; `X-Content-Type-Options`, `X-Frame-Options`.
- **PHP execution allow-list** — only `index.php` and `static.php` ever execute;
  any other `.php` (a dropped webshell) returns 404.

## Bundled plugins & skins

Pre-installed; enable with `ROUNDCUBEMAIL_PLUGINS` (comma-separated). Nothing
loads unless you list it.

### Plugins

| Plugin | Version | What it does |
|---|---|---|
| `contextmenu` | 3.3.1 | Right-click context menus (message list / folders) |
| `contextmenu_folder` | 2.0.2 | Folder management context menu |
| `swipe` | 0.6 | Touch swipe gestures (mobile) |
| `show_folder_size` | 0.7.22 | Folder size column |
| `quota` | git | Mailbox/IMAP quota display |
| `persistent_login` | 1.0.3 | "Keep me logged in" |
| `advanced_search` | 3.7 | Extended search form |
| `account_details` | 5.0.0 | Per-account info pane |
| `message_highlight` | 1.0.5 | Colour-highlight messages by rule |
| `authres` (authres_status) | 0.7.1 | Show SPF/DKIM/DMARC results |
| `thunderbird_labels` | 1.6.2 | Thunderbird-compatible coloured labels |
| `responses` | 1.3.13 | Canned-response templates |
| `easy_unsubscribe` | git | One-click List-Unsubscribe |
| `rcguard` | 1.3.2 | reCAPTCHA after failed logins |
| `kolab_2fa` | composer | Two-factor auth (TOTP / Yubikey / U2F) |
| `carddav` | composer | CardDAV address-book sync |

2FA libs (`endroid/qr-code`, `spomky-labs/otphp`, `enygma/yubikey`) are bundled
for `kolab_2fa`. Roundcube core plugins (`archive`, `zipdownload`,
`managesieve`, `password`, `newmail_notifier`, `new_user_dialog`) ship with RC
and are on by default.

### Skins

Pick one with `ROUNDCUBEMAIL_SKIN` (default `elastic`).

| Skin | Source | Notes |
|---|---|---|
| `elastic` | Roundcube core | Default, responsive |
| `elastic4mobile` | roundcube/elastic4mobile | Mobile-tuned elastic |
| `elastic-dark` | tborychowski/elastic-dark | Dark theme |
| `elastic2025` | bijanbina/Elastic2025 | Refreshed elastic look |
| `gmail` | bundled (this image) | Gmail look-alike |
| `outlook365` | bundled (this image) | Outlook 365 look-alike |
| `larry` | roundcube/larry | Classic RC 1.x skin |
| `classic` | roundcube/classic | Minimal classic skin |

## Quick start

```sh
curl -fsSLO https://raw.githubusercontent.com/eilandert/dockerized/master/src/roundcube/docker-compose.yml
$EDITOR docker-compose.yml     # set MARIADB_* + ROUNDCUBEMAIL_DB_PASSWORD,
                               # and ROUNDCUBEMAIL_DEFAULT_HOST / SMTP_SERVER
docker compose up -d
# Browse http://localhost:8080/  ->  log in with an IMAP account.
```

The compose file bundles a hardened MariaDB; point `ROUNDCUBEMAIL_DEFAULT_HOST`
/ `ROUNDCUBEMAIL_SMTP_SERVER` at your own IMAP/SMTP servers. Run behind TLS in
production (terminate at your edge proxy, forward the real client IP via
`X-Forwarded-For`). The container listens on **:8080** only.

## ⚠️ Mount ownership (because the container can't chown)

`cap_drop: [ALL]` removes `CAP_CHOWN`, so any **writable** mount must already be
owned by **uid `10001`**:

- **Named volumes** — nothing to do, they inherit it.
- **Host bind mounts** — `sudo chown -R 10001:10001 /your/bind/dir`.
- **tmpfs** — set it inline: `--tmpfs /tmp:uid=10001,gid=10001,mode=1770`.

A *Permission denied* on boot = a writable mount not owned `10001:10001`. The
fix is always the `chown` — never add a capability back. (The container prints
these same instructions in its startup logs.)

## Configuration

Driven by `ROUNDCUBEMAIL_*` env vars (IMAP/SMTP hosts+ports, DB DSN, plugin
list, skin, upload size, TLS verification). Per-deployment PHP overrides go in a
`phpfpm.conf.override` in the config volume; extra Roundcube config in a
`config.inc.php.user`. TLS to your mail server is **verified by default** — set
`ROUNDCUBEMAIL_SSL_CA` to pin a private CA, or (trusted LAN only, allows MITM)
`ROUNDCUBEMAIL_SSL_VERIFY=0`.
