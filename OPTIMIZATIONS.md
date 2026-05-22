# Dockerfile Optimizations — Phase 4 (May 2026)

Builds on the Phase 1–3 work in `.memories/repo/dockerfile-uniformity-fixes.md`
(uniformity, HEALTHCHECK, OCI labels, naming, apt cleanup). This phase focuses
on **build-speed via BuildKit cache mounts** and **template DRY-up**.

## What changed

### Templates (source of truth)

All five templates now start with `# syntax=docker/dockerfile:1.7` and use
BuildKit cache mounts for apt:

```dockerfile
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt,sharing=locked \
    set -ex ;\
    rm -f /etc/apt/apt.conf.d/docker-clean ;\
    apt-get update ;\
    apt-get install -y --no-install-recommends ...
```

Why each piece matters:

- **`# syntax=docker/dockerfile:1.7`** — enables BuildKit frontend features
  (cache mounts, COPY `--chmod`, heredocs).
- **`--mount=type=cache,target=/var/cache/apt`** — apt's `.deb` archive cache.
  Survives across builds; package files are reused on incremental rebuilds.
- **`--mount=type=cache,target=/var/lib/apt`** — apt's package index cache.
  Same idea: `apt-get update` reuses lists across builds.
- **`rm -f /etc/apt/apt.conf.d/docker-clean`** — the Debian/Ubuntu base image
  ships a `DPkg::Post-Invoke` hook that wipes `/var/cache/apt/archives/` after
  every `apt-get install`. With the cache mount that wipe would invalidate the
  shared cache for every other build. Removing the stub keeps `.deb` files in
  the mount.
- **No `rm -rf /var/lib/apt/lists/*`** — the lists are now on a cache mount,
  not in the image layer. Cleaning them is redundant and would defeat the
  cache.
- **`COPY --chmod=0755 bootstrap.sh /bootstrap.sh`** — sets perms at COPY
  time, lets us drop the separate `chmod +x /bootstrap.sh` in the RUN.

### Files touched (source of truth)

- `src/nginx/Dockerfile.template`
- `src/apache-phpfpm/Dockerfile-template`
- `src/php-fpm/Dockerfile-template.header`, `.footer`, `.php`
- `src/base/Dockerfile-template`

The php-fpm footer still enumerates each `rm -rf /etc/php/X.Y` on its own
line — the generator's per-version `safe_sed "rm -rf /etc/php/${version}"
"#rm -rf /etc/php/${version}"` relies on that. Do not collapse those into a
loop.

### Regenerated (86 files)

All `Dockerfile-*` in `src/{base,php-fpm,nginx,angie,apache-phpfpm}` were
regenerated via:

```bash
bash src/base/.generate.sh && \
bash src/php-fpm/.generate.sh && \
bash src/nginx/.generate.sh && \
bash src/apache-phpfpm/.generate.sh && \
bash src/angie/.generate.sh
```

Angie is generated from nginx via copy+sed (see `src/angie/.generate.sh`),
so it inherits all nginx template improvements automatically.

### Non-generated Dockerfiles (full rewrite)

Same cache-mount + `COPY --chmod=0755` pattern applied to:

- `src/valkey/Dockerfile-{deb,ubu}`
- `src/openssh/Dockerfile-{deb,ubu}` (note: `Dockerfile-ubu` still has
  `FROM eilandert/debian-base:stable` — that's a pre-existing inconsistency
  not introduced here; investigate before flipping)
- `src/dovecot/Dockerfile-{deb,ubu}` (apk-based; uses `/var/cache/apk` mount)
- `src/dovecot-ubuntu/Dockerfile-{deb,ubu}`
- `src/rspamd/Dockerfile` (apk-based)
- `src/reprepro/Dockerfile`
- `src/clamav-unofficial-signatures/Dockerfile{,-alpine}`
- `src/redis6-scratch/Dockerfile` (multi-stage build; apk cache mount on
  builder stage)
- `src/wosbotv4/Dockerfile{,-main,-release}` (Python; added pip cache mount
  `--mount=type=cache,target=/root/.cache/pip`)

### Non-generated Dockerfiles (minimum-touch)

These got `# syntax=docker/dockerfile:1.7` prepended and `COPY bootstrap.sh`
upgraded to `COPY --chmod=0755 bootstrap.sh` via the cleanup pass, but RUN
bodies were left alone (the install logic is component-specific and a full
rewrite risks breaking working builds):

- `src/aptly/Dockerfile`
- `src/docker-cms/Dockerfile`
- `src/letsencrypt/Dockerfile`
- `src/mariadb/Dockerfile-{deb,ubu,.debian,.ubuntu}`
- `src/nginx-alpine/Dockerfile`
- `src/postfix/Dockerfile-{deb,ubu}`
- `src/psol-build/Dockerfile`
- `src/rbldnsd/Dockerfile`
- `src/redis/Dockerfile-{deb,ubu}`
- `src/roundcube/Dockerfile-{deb,ubu,deb.multistage}`
- `src/roundcube-new/Dockerfile`
- `src/roundcobe-old/Dockerfile-{deb,ubu,template}`
- `src/rspamd-git/Dockerfile-{deb,ubu,official,stable}`
- `src/sitemap_warmup/Dockerfile`
- `src/unbound/Dockerfile`
- `src/vimbadmin/Dockerfile`
- `src/vimbadmin-ubuntu/Dockerfile-{deb,ubu}`

### Out of scope

Edits to Dockerfiles outside `modules/dockerized/` (e.g. `modules/webtester`,
`tools/website-tester`, `modules/nginx/{http-naxsi,ipscrub,http-auth-jwt,
http-length-hiding-filter}`, `deb/psol/`) were initially made and then
reverted at the user's request — those live in other submodules / scopes and
should be optimized as separate efforts. The same cache-mount pattern from
this doc applies; copy and adapt when those efforts happen.

## Build impact

- **Incremental rebuild speedup**: apt-get download is skipped entirely when
  the cache mount has the package; first build populates the cache, every
  subsequent build reuses it. Expect 5–30× speedup on the apt step depending
  on package set size.
- **Image size**: essentially unchanged. Apt lists were already being cleaned
  in Phase 2; now they live on the mount instead of being installed-then-
  deleted, which is slightly cleaner but not size-changing.
- **Cache invalidation**: BuildKit invalidates the cache mount only when the
  RUN command itself changes. Adding/removing packages still busts the layer
  cache, but the underlying `.deb` files come from the persistent mount —
  so the layer rebuild is fast.

## What this phase did NOT do

- **Non-root USER**: each service needs per-component evaluation (nginx :80,
  php-fpm socket perms, postfix/dovecot privilege model). Worth a follow-up
  pass per-service, not generically.
- **bootstrap.sh `set -e`**: existing scripts have intentionally-tolerated
  failures (optional `cp`, `rm` of files that may not exist, background
  nullmailer). Blanket `set -e` would break them. They already `exec` the
  final command, which is the relevant correctness property.
- **Full rewrite of roundcube/roundcobe-old**: 200-line composer/curl/git
  chains. Minimum-touch only; rewriting risks breaking a working build for
  marginal gain.
- **Generator refactors**: `generate-lib.sh` and the five `.generate.sh`
  scripts are already well-factored (per-version sed, marker stripping,
  multi-PHP composition). No DRY wins worth the risk.

## Hardening pass (Phase 5)

### `base/Dockerfile-template`
- Tightened `/etc/login.defs`: `UMASK 027`, `PASS_MAX_DAYS 90`, `PASS_MIN_DAYS 1`, `PASS_WARN_AGE 7`, `LOGIN_RETRIES 3`, `LOG_OK_LOGINS yes`.
- Added `/etc/profile.d/00-hardening.sh` enforcing `umask 027`, disabling core dumps, setting `TMOUT=900`, and constraining bash history.
- Appended `* hard core 0`, `root hard core 0` to `/etc/security/limits.conf`.
- Created empty `/etc/cron.allow` (0600) and `/etc/securetty` (0600) — no interactive cron / root tty by default.
- Stripped world-write from `/usr/local/{bin,sbin}`.
- Expanded the explicit `remove_path` list to drop `wall write` in addition to `dmesg su sudo`.
- Added a `find /usr /bin /sbin -perm -4000 -o -perm -2000 -exec chmod a-s {} \;` sweep so every remaining setuid/setgid binary in the base image is neutralised. Child images that genuinely need setuid (e.g. openssh re-installing sudo) re-add the bit explicitly.
- Added `STOPSIGNAL SIGTERM` and `LANG=C.UTF-8` / `LC_ALL=C.UTF-8`.

### `php-fpm` header + footer (privilege separation across the whole stack)
- **New dedicated `phpfpm` user** (uid/gid 1500, `/usr/sbin/nologin`) created in the header. NOT a member of `www-data`.
- Footer patches every `pool.d/www.conf` *before* `mv /etc/php /etc/php.orig`, so the runtime `cp /etc/php.orig/* /etc/php` in the angie/nginx/apache bootstraps picks up the override:
  - `user = phpfpm`
  - `group = phpfpm`
  - `listen.owner = phpfpm`
  - `listen.group = www-data`  (web server reaches the socket via group)
  - `listen.mode = 0660`
- This applies to single-version *and* multi-PHP variants (the `/etc/php/*/fpm/pool.d/www.conf` glob hits every installed version).
- Pre-create `/run/php`, `/var/log/php` as `phpfpm:www-data 0750`, and `/var/www` as `phpfpm:www-data 2750` (setgid → files created by PHP inherit `www-data` group so the web server can read static assets).
- `src/{php-fpm,angie,nginx,apache-phpfpm}/bootstrap.sh` runtime `mkdir /run/php` patched from `www-data:www-data 755` → `phpfpm:www-data 750` to stay consistent with build-time perms.
- `chmod 0755` (not just `+x`) on the installed `wp` and `composer` so file mode is deterministic.
- Added `STOPSIGNAL SIGQUIT` for graceful FPM shutdown.

**Effect**: in every angie/nginx/apache-php image the web server still runs as `www-data` and reaches PHP-FPM via the socket, but the actual PHP workers run as `phpfpm`. Any setuid binary locked to `root:www-data` (like sudo in the cms image) is unreachable from PHP.

### `agent` operator/AI user + sudo (all PHP images)
- New `agent` user (uid/gid 1501, `/bin/bash`, home `/home/agent`) created in the php-fpm header. Supplementary groups: `www-data` (so agent can read `/var/www` mode 2750) **and** `sudo` (so agent can execute the locked-down sudo binary). Empty `~/.ssh` pre-created `0700 agent:agent` for SSH key injection.
- `sudo` re-installed in the php-fpm footer (the base image strips it; we reinstall and immediately lock it):
  - Binary perm `4750 root:sudo` — only root and members of the `sudo` group can execute. The Debian `sudo` package already manages this group; we pre-create it in the header so agent can be added before the package install.
  - `/etc/sudoers.d/10-agent` (mode 0440, validated with `visudo -c`) grants `agent ALL=(ALL) NOPASSWD: ALL` and sets `secure_path`.
- The three-way separation, now with binary-level isolation:
  - `agent` → in `sudo` group → **can** execute sudo binary, **is** in sudoers → full root via `sudo`.
  - `www-data` (web server) → **not** in `sudo` group → cannot even execute the sudo binary.
  - `phpfpm` (PHP workers) → in neither group → cannot reach sudo and cannot write `/var/www` from anyone else's perspective.
- Why the dedicated `sudo` group instead of `www-data`: the web server runs **as** www-data, so any www-data-group-execable binary is reachable from web processes. A buggy sudoers edit, a sudo CVE in argument parsing, or a sudo-via-symlink trick would then have a foothold from the web request path. Binding sudo execution to a group that web processes are not in makes that whole class of issue unreachable, regardless of sudoers config.
- Propagates automatically to every nginx-php / angie-php / apache-php / multi / cms image via the FROM chain — no per-image work needed. The cms image's own sudo lockdown lines (re-applied defensively) also use `root:sudo`.

### `nginx/Dockerfile.template` (propagates to `angie` via `.generate.sh`)
- After install, `chown -R root:www-data /etc/nginx.orig /etc/modsecurity.orig` and `chmod -R go-w` so workers can read but never write the conf tree.
- Pre-create `/var/cache/nginx` and `/var/log/nginx` as `www-data:www-data` mode 0750.
- Setuid/setgid sweep across `/usr` (same approach as base, scoped to this layer).
- Added `STOPSIGNAL SIGQUIT`.

## CMS merge (Phase 5)

The old `src/docker-cms/Dockerfile` (debian-base + sleep-infinity admin
shell) and the `debian-angie-php85` web stack are merged into a single
**`debian-angie-cms`** image:

- New `src/docker-cms/Dockerfile-deb` `FROM docker.io/eilandert/angie:deb-8.5`.
- All cms-toolbox packages installed on top: `cron, git, imagemagick, jq, less, libvips42, mariadb-client, mc, nano, openssh-client, patch, php-vips, pv, rsync, sudo, unzip, wget, zip`.
- **`git`** and **`patch`** are now present (the previous image had git but not patch).
- Composer and WP-CLI installed to `/usr/local/bin`.
- `wp` completion installed to `/etc/profile.d/wp-completion.sh`.
- `www-data` shell set to `/bin/bash`; root `.bashrc` aliases `wp` to run as www-data.
- No `bootstrap.sh` in the cms layer — inherits the full angie bootstrap, so the container actually serves the CMS via angie+php-fpm-8.5 instead of just `sleep infinity`.
- **Privilege separation:** PHP-FPM workers run as a dedicated `cmsphp` user (uid/gid 1500, shell `/usr/sbin/nologin`), **not** www-data. The pool config in `/etc/php.orig/8.5/fpm/pool.d/www.conf` is patched at build time so `user = cmsphp`, `group = cmsphp`, `listen.owner = cmsphp`, `listen.group = www-data` (mode 0660) — angie (running as www-data) can still proxy to the FPM socket but the worker process itself runs as cmsphp.
- `/var/www` owned `cmsphp:www-data` mode `2750` — angie can read static assets, only PHP/wp-cli can write.
- Hardening: setuid/setgid sweep across `/usr` except `/usr/bin/sudo`; `sudo` re-locked to `4750 root:www-data`. Because `cmsphp` is **not** in the `www-data` group, PHP code (and anything spawned by it) cannot invoke sudo even if a CMS exploit lands. The interactive `wp` alias in `/root/.bashrc` runs as `sudo -u cmsphp` so admin work still uses the same uid as the workers.
- Bake target renamed `cms` → `debian-angie-cms` (with `latest` tag preserved), and chained to the local `debian-angie-php85` build via `contexts = {…}` so a single `bake debian-angie-cms` builds the whole stack.

## CMS tuning (Phase 6)

`debian-angie-cms` now ships a complete CMS-ready stack rather than just
"angie + tools". Everything lives in `src/docker-cms/` and is COPY'd into
the `.orig` directories so the runtime `cp /etc/X.orig/* /etc/X` in the
angie bootstrap picks it up on first run (volumes still override).

### PHP tuning (`cms.ini` → `/etc/php.orig/8.5/fpm/conf.d/90-cms.ini`)
- `memory_limit=512M`, `upload_max_filesize=64M`, `post_max_size=64M`, `max_input_vars=10000`, `max_execution_time=120`.
- Realpath cache `4096k / 600s`.
- OPcache: `memory_consumption=256`, `max_accelerated_files=20000`, `validate_timestamps=0` (production), `jit=tracing`, `jit_buffer_size=128M`.
- Hardened session cookies (`HttpOnly`, `Secure`, `SameSite=Lax`, strict mode).
- `expose_php=Off`, errors log to stderr (visible via `docker logs`).
- `disable_functions` covers shell escapes + pcntl process control. `parse_ini_file` / `curl_multi_exec` deliberately allowed (guzzle, well-behaved plugins use them).

### FPM `[www]` pool tuning
Originally lived in `cms-pool.conf` shipped as `pool.d/zz-cms.conf`, but a second file declaring `[www]` is a duplicate-pool error to FPM. Now appended directly to the existing `[www]` block in `www.conf` by the php-fpm footer's per-pool loop, so every PHP image gets it:
- `pm=dynamic` with `max_children=25`, `start=4`, sane `min/max_spare`, `max_requests=500`.
- `pm.status_path=/fpm-status`, `ping.path=/fpm-ping`, `ping.response=pong`.
- Slowlog → `/proc/self/fd/2` (docker logs), `request_slowlog_timeout=5s`, `request_terminate_timeout=120s`.
- `catch_workers_output=yes`, `decorate_workers_output=no` — every worker stderr line lands in `docker logs` raw.
- Emergency restart `10 SEGVs / 1m`, `process_control_timeout=10s`.
- `chdir=/var/www`.
- The user/group/listen patching above the `--- myguard hardening ---` marker is unchanged: phpfpm worker, socket group www-data.

### Angie tuning (`cms-angie.conf` → `conf.d/cms.conf`)
- `client_max_body_size 64m`, `client_body_timeout 60s`, `send_timeout 60s` — uploads + slow theme updates don't 413/504.
- `fastcgi_read_timeout 300s`, larger `fastcgi_buffers 16 16k`.
- `server_tokens off`, gzip enabled for HTML/CSS/JS/JSON.

### Site snippets
- `snippets/wordpress.conf` — `try_files`, hashed-asset caching, deny rules for `wp-config.php` / `.env` / dotfiles / PHP-in-uploads, rate-limited `wp-login.php` and `xmlrpc.php` (requires a `limit_req_zone … zone=cms_login` block in `http{}`).
- `snippets/drupal.conf` — pretty URLs + image styles + private-path denies for Drupal 9/10/11.

### ImageMagick hardening (`imagemagick-policy.xml`)
- Replaces the stock `/etc/ImageMagick-6/policy.xml` (orig saved as `.orig`).
- Disables every Ghostscript-backed coder (PS, EPS, PDF, XPS) and the URL / HTTP / HTTPS / FTP / MSL / MVG modules — the entire ImageTragick CVE family.
- Resource caps: 256 MiB memory, 1 GiB disk, 16 KP w/h, 128 MP area, 120 s wallclock, 2 threads.
- Refuses indirect `@path` reads (file:@/etc/passwd attack).

### Image-optim toolchain
- `jpegoptim optipng pngquant gifsicle webp` so CMS image optimisers (WP Smush, EWWW, Drupal ImageAPI Optimize) work without complaining about missing binaries.
- `libvips42 + php-vips` already in place — set `WP_IMAGE_EDITOR_VIPS=1` or use the relevant Drupal/Bedrock toggle to prefer libvips.

### Admin / DX tooling
- **wp-cli** + completion already there. **Built-in `wp-cli/doctor-command` and `wp-cli/profile-command`** pre-installed at build (in `/opt/wp-cli`, owned `phpfpm:www-data`) so they survive stateless restarts.
- **drush** installed via composer into `/opt/drush`, on `$PATH`.
- **`cms-backup`** (`/usr/local/bin/cms-backup`) — pass a doc-root, get a timestamped DB dump (gzipped) + `wp-content` tarball + sanitized `wp-config.php` (secrets stripped) + manifest in `/var/www/_backups/<site>/<stamp>/`. Auto-prunes older than `$RETAIN_DAYS` (default 14).
- **`restic`** + **`rclone`** for off-site backup.
- **`goaccess`** for HTML log reports.
- **`mariadb-client`** + the bootstrap auto-generates `/root/.my.cnf` from `$DB_HOST`/`$DB_USER`/`$DB_PASS`/`$DB_NAME` env vars so `mysql` "just works" in `docker exec`.

### Cron / wp-cron
- Custom `bootstrap-cms.sh` starts `cron` in the background then `exec`s the inherited angie bootstrap.
- `/etc/cron.d/cms-wpcron` runs `wp cron event run --due-now` every minute as `phpfpm` for every `/var/www/*/` doc-root containing `wp-config.php`. Other doc-roots silently skipped.

### Privilege model recap
- Web server: `www-data`.
- PHP-FPM workers: `phpfpm` (uid 1500, not in `www-data` group).
- Cron jobs running wp-cli: `phpfpm`.
- `/var/www/*` owned `phpfpm:www-data` mode 2750 — workers write, web server reads, group inherits.
- `/usr/bin/sudo`: `4750 root:www-data`. PHP cannot reach it; admin `docker exec` shell uses `sudo -u phpfpm` aliases for `wp` / `drush`.

## Dual FPM pools — `[www]` + `[agent]` (Phase 7)

Every PHP-bearing image (php-fpm, nginx-php*, angie-php*, apache-php*, cms)
now ships **two FPM pools** in one FPM master, with completely separate
identity, socket, and reachability:

| Pool | User | Socket | Socket perms | `pm` | Audience |
|---|---|---|---|---|---|
| `[www]` | `phpfpm` | `/run/php/php<ver>-fpm.sock` | `phpfpm:www-data 0660` | `dynamic` (sized for HTTP load) | Untrusted web traffic via angie / nginx / apache |
| `[agent]` | `agent`  | `/run/php/php<ver>-agent.sock` | `agent:www-data 0660` | `ondemand` (rare bursts) | Trusted operator / MCP / wp-cli (reachable by the web server so MCP can be exposed over HTTPS) |

The split is enforced at the **kernel socket-permission level**, not just in
config. The trust boundary is **`phpfpm` ↔ `agent`**, not web-vs-not-web:

- `[www]` socket is `phpfpm:www-data 0660`. Angie/nginx/apache (www-data) can connect; the agent operator can too (agent is also in www-data so it can read `/var/www`).
- `[agent]` socket is `agent:www-data 0660`. The web server (www-data) **can** connect — this is intentional, so MCP can be served over HTTPS via the public Angie. The agent user can connect directly. The `[www]` phpfpm worker (uid 1500 `phpfpm`, in **neither** www-data nor sudo) **cannot** — the kernel returns EACCES. A compromised public PHP worker cannot pivot to the agent pool.
- The pool worker process for `[agent]` runs as `agent` (uid 1501, in sudo + www-data, shell `/bin/bash`). Code in this pool is privileged on purpose: MCP and operator scripts run wp-cli, backups, bulk fixes, and need sudo. Reachability from www-data is the trade-off for not running a second internal-only web server just for MCP.

### `[www]` pool defaults (HTTP-traffic-tuned)
- `pm = dynamic`, `pm.max_children = 25`, `pm.start_servers = 4`, `pm.min_spare_servers = 2`, `pm.max_spare_servers = 8`, `pm.max_requests = 500`.
- `request_slowlog_timeout = 5s`, `request_terminate_timeout = 120s`.
- `pm.status_path = /fpm-status`, `ping.path = /fpm-ping`.
- Hardening block: `expose_php=Off`, `allow_url_include=Off`, session strict-mode + httponly, errors → stderr, `security.limit_extensions = .php`, `process.dumpable = no`, plus the global `disable_functions` from `cms.ini` for the cms image.
- (cms image only: `cms-pool.conf` adds `slowlog → stderr`, `catch_workers_output=yes`, emergency restart thresholds.)

### `agent` user (FPM `[agent]` pool worker, also the operator account)
Uid 1501, shell `/bin/bash`, member of `www-data` (read `/var/www`) and `sudo` (passwordless via `/etc/sudoers.d/10-agent`). The `[agent]` pool runs **as `agent` itself** — no separate lower-privilege worker. This is deliberate: MCP and operator code legitimately need wp-cli, backups, bulk fixes that require sudo / unrestricted `exec`. The previous design used a separate `angie` uid-1502 worker and an `angie:sudo`-only socket to keep web traffic out; that was dropped in favour of exposing MCP via the public HTTPS endpoint (Angie can connect), with the `[www]`-vs-`[agent]` permission split as the real isolation boundary.

### `[agent]` pool defaults (MCP/operator-tuned)
- `pm = ondemand`, `pm.max_children = 4`, `pm.process_idle_timeout = 60s`, `pm.max_requests = 200` — no warm workers for traffic that arrives once an hour.
- `request_slowlog_timeout = 30s`, `request_terminate_timeout = 600s` — backups, exports, bulk fixes can run for minutes.
- `php_admin_value[memory_limit] = 1G`, `max_execution_time = 600`.
- **`php_admin_value[disable_functions] =`** (deliberately empty) — admin code is trusted; `exec`/`shell_exec`/`proc_open` need to work for wp-cli, drush, system maintenance. Untrusted code paths in the `[www]` pool cannot reach this socket (group is `www-data`, and `phpfpm` is not in `www-data`); the public web server can, by design.
- `security.limit_extensions = .php` retained.
- `chdir = /var/www`, `catch_workers_output = yes` — admin pool output also goes to `docker logs`.

### How to hit the agent pool
- Via the public Angie/nginx/apache: routes that proxy to `unix:/run/php/php<ver>-agent.sock` (e.g. `/wp-json/mcp/...`) work because `listen.group = www-data`. This is how MCP-over-HTTPS reaches it.
- From inside the container as `agent`: `cgi-fcgi -bind -connect /run/php/php8.5-agent.sock /var/www/<site>/path/to/admin.php`.
- Via a side proxy (mcp-bridge, fastcgi-proxy) running as `agent` or `www-data`.
- The `[www]` phpfpm worker **cannot** reach it — by design — so even a compromised public PHP worker cannot pivot.

The agent pool config is written into every `/etc/php/<ver>/fpm/pool.d/agent.conf` during the php-fpm build, then the standard `mv /etc/php /etc/php.orig` snapshot picks it up. The angie/nginx/apache bootstraps `cp` it into `/etc/php` on first start.

### Snuffleupagus loaded globally, neutralised per-pool for `[agent]`
The `php<ver>-snuffleupagus` package is installed in every Debian PHP image (Ubuntu still strips it via `PHP_UBUNTU_MISSING_EXTS` — mirror gap). It loads at the FPM master level and is active for the `[www]` pool using the upstream-provided `snuffleupagus.rules`. PHP has no per-pool extension-unload mechanism — one master, one extension table — so we can't truly "skip" it for `[agent]`. Instead the build ships an empty rules file at `/etc/snuffleupagus/agent-noop.rules`, and the `[agent]` pool config sets:

```
php_admin_value[sp.configuration_file] = /etc/snuffleupagus/agent-noop.rules
```

Effect: snuffleupagus is loaded but registers zero rules in the `[agent]` worker, so `exec`, `eval`, file inclusion etc. are unconstrained for trusted operator code. The `[www]` worker continues to enforce the full ruleset.

## Angie / NGINX runtime hardening (Phase 7)

Five new bundled config files ship in every nginx-php / angie-php image
(and downstream `debian-angie-cms`). They land in `/etc/nginx.orig/` (resp.
`/etc/angie.orig/`) at build time, so the existing bootstrap's
`cp /etc/X.orig/* /etc/X/` on first run copies them into the live tree.
Stored in `src/nginx/` as the source of truth; the angie generator copies
them verbatim (no sed needed — they're distro-neutral).

### `conf.d/01-hardening.conf` — http-context defaults
- `server_tokens off`, `more_clear_headers Server` (no-op without headers-more).
- Slowloris guards: `client_body_timeout 12s`, `client_header_timeout 12s`, `send_timeout 12s`, `keepalive_timeout 30s`, `reset_timedout_connection on`.
- Buffer caps: `client_body_buffer_size 128k`, `large_client_header_buffers 4 8k`, default `client_max_body_size 16m` (cms.conf overrides to 64m).
- `fastcgi_hide_header X-Powered-By/X-Generator/X-Drupal-*` and `proxy_hide_header` equivalents — strip back-end fingerprinting.
- Reasonable gzip defaults (cms image extends type list).
- `$bad_method` map flags TRACE/TRACK/DEBUG; `$is_bad_bot` map flags nikto/sqlmap/nmap/masscan/dirbuster/wpscan/acunetix/nessus/empty-UA. Use either in a per-server `if ($is_bad_bot)` block.

### `conf.d/02-rate-limits.conf` — global limit zones
- `limit_conn_zone conn_per_ip` with default `limit_conn conn_per_ip 50`.
- `limit_req_zone` for `cms_login` (5 r/m), `api` (100 r/m), `admin` (30 r/m).
- `limit_req_status 429` / `limit_conn_status 429` — return 429 not 503.

### `snippets/security-headers.conf`
`include` in any server{} for: X-Frame-Options SAMEORIGIN, X-Content-Type-Options nosniff, X-XSS-Protection 0 (explicit), Referrer-Policy strict-origin-when-cross-origin, Permissions-Policy with all sensors denied, HSTS preload-eligible. COOP/COEP/CORP commented out — opt-in once CMS is OK with isolation.

### `snippets/ssl-hardening.conf`
TLS 1.2 + 1.3 only, modern ECDHE/CHACHA20 cipher list, X25519/secp384r1/prime256v1 curves, ssl_session_tickets off, ssl_stapling on, ssl_early_data off by default. Pair with your per-site `ssl_certificate` block.

### `snippets/deny-hidden-files.conf`
Universal denies for dotfiles (except `.well-known`), the standard credential-leak files (wp-config / settings.php / composer / yarn lock / .env / .htaccess), backup extensions (.bak/.swp/.old), and `.php` inside `/uploads/|/files/|/cache/|/tmp/` (the file-upload RCE vector).

## PHP-FPM pool hardening (Phase 7)

The per-pool sed loop in the php-fpm footer now also sets, on every `www.conf`:
- `security.limit_extensions = .php` — FPM refuses to execute anything else.
- `process.dumpable = no` — no core dumps from workers.
- `clear_env = no` — keep parent env (FPM defaults strip it).

And appends (idempotently, guarded by a marker line) a hardening block:
- `php_admin_value[expose_php] = Off`
- `php_admin_value[allow_url_include] = Off` (kept `allow_url_fopen` ON — Composer + WordPress core updates require it)
- `php_admin_value[session.use_strict_mode] = 1`, `session.cookie_httponly = 1`
- `php_admin_flag[log_errors] = on`, `display_errors = off`, `error_log = /proc/self/fd/2` (errors land in `docker logs`).

These are pool-level `php_admin_*` settings so individual scripts cannot `ini_set()` around them.

## How to extend

When adding a new component:

1. Start the Dockerfile with `# syntax=docker/dockerfile:1.7`.
2. Use the apt cache-mount pattern in every RUN that calls `apt-get`.
3. Use `COPY --chmod=0755` for executable scripts instead of a separate
   `chmod +x` in RUN.
4. For Python: add `--mount=type=cache,target=/root/.cache/pip` on RUN
   blocks that call pip.
5. For apk: add `--mount=type=cache,target=/var/cache/apk`.
6. Keep the existing OCI label block, HEALTHCHECK, and `--no-install-
   recommends` patterns from Phase 1–3.
