# PHP-FPM pool layout

Every php-fpm image (and everything that builds on it — `docker-cms`,
`nginx-php`, `angie-php`) ships two pools side-by-side:

| pool      | worker user      | socket                                  | trust level   | reachable via                                |
|-----------|------------------|-----------------------------------------|---------------|----------------------------------------------|
| `[www]`   | `phpfpm:phpfpm`  | `/run/php/php<ver>-fpm.sock`            | **untrusted** | public HTTP                                  |
| `[agent]` | `agent:www-data` | `/run/php/php<ver>-agent.sock`          | **trusted**   | only allow-listed paths (e.g. `/wp-json/mcp/`) |

Both sockets are mode `0660` with group `www-data` so the reverse proxy
(angie/nginx, running as `www-data`) can connect to either. The trust
boundary is the path-based routing in the reverse-proxy config, plus
upstream auth (bearer + per-request `_token` for MCP).

## Why two pools?

The `[www]` pool faces the public internet and runs untrusted plugin
code. It is hardened: shell-exec functions disabled, Snuffleupagus
strict ruleset, modest memory/exec limits, OPcache frozen
(`validate_timestamps=0`), no core dumps.

The `[agent]` pool serves a privileged operator endpoint (MCP/WP-CLI,
backups, image conversions, bulk SEO ops). It needs `proc_open` for
WP-CLI, generous memory/timeouts for bulk operations, large upload
limits for base64-encoded media, and `opcache.validate_timestamps=1`
because the operator routinely hot-patches plugin files via
`myguard/write-file` and `myguard/apply-patch`.

Keeping the privileged operator code in a separate pool means a
compromised public worker cannot escalate by writing into a privileged
process's address space — they're separate uids, separate sockets,
separate Snuffleupagus rulesets. The only thing they share is the
opcache memory, and OPcache is per-pool when `opcache.preload` is unset
(which it is).

## Identity and filesystem perms

The two worker users:

| user     | uid  | gid       | supplementary    | what they can do                                                       |
|----------|------|-----------|------------------|------------------------------------------------------------------------|
| `phpfpm` | 1500 | `phpfpm`  | _(none)_         | run the public CMS workers; **cannot** read `agent` files (no www-data) |
| `agent`  | 1501 | `www-data`| `sudo`, `www-data`| run privileged operator code, `sudo`, write to shared g+w WP dirs      |

`agent` has supplementary `sudo` so passwordless `sudo` works for it
(see `/etc/sudoers.d/10-agent`). `phpfpm` deliberately does NOT have
any supplementary group — a compromised public worker cannot reach
`sudo`, cannot read or write anything not owned by uid 1500.

The conventional WP directory layout used by `docker-cms`:

```
/var/www/<site>/                    phpfpm:www-data 0755
├── wp-content/                     phpfpm:www-data 0755
│   ├── uploads/                    phpfpm:www-data 2775   # setgid + group write
│   ├── plugins/                    phpfpm:www-data 2775
│   ├── themes/                     phpfpm:www-data 2775
│   ├── mu-plugins/                 phpfpm:www-data 2775
│   ├── upgrade/                    phpfpm:www-data 2775
│   └── cache/                      phpfpm:www-data 2775
```

Both workers can write under `wp-content/*` because:

- `phpfpm` (uid 1500) is the owning uid (`u+w`).
- `agent` (gid 33 = www-data) has the group write bit via `g+w`.

The setgid bit on the directories ensures new files inherit the
`www-data` group regardless of which pool created them, so both pools
stay interoperable forever.

## Why `[agent].group = www-data` and not `agent`?

If we ran `agent` workers as `agent:agent`, files they create would be
`agent:agent` and the `[www]` pool (no supplementary groups) would not
be able to read or write them. Running as `agent:www-data` makes new
files `agent:www-data 0664` (default umask) which the `[www]` pool can
still operate on. The supplementary `sudo` group is preserved via
`/etc/sudoers.d/10-agent`.

## Why `listen.owner = <pool worker>` and not `angie`?

`listen.owner` is just the user that owns the socket inode — angie
doesn't authenticate as it, it traverses by the **group bit**
(`listen.group = www-data`). For consistency we set `listen.owner` to
each pool's own worker user (`phpfpm` for `[www]`, `agent` for
`[agent]`). Use anyone you like; only the group + mode matter for
who can connect.

## Where the config lives

The pool configuration is **generated at image build time** by
`Dockerfile-template.footer`, then frozen into `/etc/php.orig/`. The
bootstrap copies `/etc/php.orig/* → /etc/php/` with `cp -rn`
(no-clobber) on first boot, so host bind-mount edits survive container
restarts.

| file                                                         | layer       | purpose                                             |
|--------------------------------------------------------------|-------------|-----------------------------------------------------|
| `pool.d/www.conf`                                            | `php-fpm`   | public pool — hardened, CMS-sized                   |
| `pool.d/agent.conf`                                          | `php-fpm`   | trusted pool — empty disable_functions, permissive SP |
| `cli/conf.d/06-snuffleupagus-cli.ini`                        | `php-fpm`   | CLI SAPI sp.configuration_file (silences load warning) |
| `conf.d/90-cms.ini` (from `docker-cms`)                      | `docker-cms`| globals only — expose_php, timezone, logging        |

### Per-pool, NOT in global conf.d

`disable_functions`, `memory_limit`, `opcache.*`, `upload_max_filesize`,
`session.*`, Snuffleupagus `sp.configuration_file` — all of these MUST
live in the per-pool `pool.d/*.conf`, not in the global `conf.d/*.ini`.

There are two reasons:

1. **`disable_functions` is `PHP_INI_SYSTEM`** and is processed once in
   the FPM master. A pool-level
   `php_admin_value[disable_functions] =` (empty) cannot **re-enable**
   functions that were already disabled globally. Setting it in
   `conf.d/90-cms.ini` would permanently lock the `[agent]` pool out
   of `proc_open` / WP-CLI even though that's exactly what it needs.

2. **The two pools have legitimately different requirements**.
   `[www]` wants `opcache.validate_timestamps=0` (max perf, frozen
   cache); `[agent]` wants `=1` (catches hot-patched plugin files).
   `[www]` wants 512M memory limit; `[agent]` wants 1G. `[www]` runs
   the `wordpress-strict` Snuffleupagus ruleset; `[agent]` runs the
   permissive `mcp-agent` ruleset.

Anything we'd be tempted to put in a global `*.ini` either applies to
both pools identically (in which case it's safe — `expose_php`,
`timezone`, logging routing) or it shouldn't be global at all.

## Layered overrides

The cms image (`docker-cms/Dockerfile-deb`) adds **only** what's safe
globally:

```ini
# 90-cms.ini — see src/docker-cms/cms.ini
expose_php                    = Off
date.timezone                 = Europe/Amsterdam
display_errors                = Off
log_errors                    = On
error_log                     = /proc/self/fd/2
file_uploads                  = On
```

Everything that used to live there (`memory_limit`, `disable_functions`,
opcache, sessions, upload sizes) was moved into the per-pool
`pool.d/www.conf` block emitted by the template, where it can differ
between the public and operator pools.

## Snuffleupagus

Loaded globally via `/etc/php/<ver>/mods-available/snuffleupagus<ver>.ini`,
which is symlinked into BOTH `fpm/conf.d/` AND `cli/conf.d/`. The package
ships five rulebooks; pools and the CLI pick one via
`sp.configuration_file`:

- `[www]` → `/etc/php/<ver>/php-snuffleupagus/wordpress-strict.rules`
  (full SP HEAD-safe WP ruleset — belt-and-braces with the per-pool
  `disable_functions`).
- `[agent]` → `/etc/php/<ver>/php-snuffleupagus/mcp-agent.rules`
  (permissive — allows `proc_open` / `exec` / `passthru` that MCP and
  WP-CLI need).
- CLI SAPI → `mcp-agent.rules` as well, via the auto-generated
  `cli/conf.d/06-snuffleupagus-cli.ini`. Without this, every `wp` or
  `php -r` invocation prints a "No configuration specified via
  sp.configuration_file" warning.

The strict ruleset is the *defence in depth* layer for the public
pool: even if a future operator accidentally removes the per-pool
`disable_functions` line, Snuffleupagus still blocks shell exec.

## Routing example (angie / nginx)

The reverse proxy fans out by `location`:

```nginx
# Privileged MCP path → agent pool, IP allow-list + auth, no ModSecurity
location ^~ /wp-json/mcp/ {
    allow 2001:db8::/64;            # operator network
    allow 198.51.100.7;             # operator IPv4 fallback
    deny all;
    modsecurity off;
    include fastcgi.conf;
    fastcgi_param SCRIPT_FILENAME /var/www/<site>/index.php;
    fastcgi_pass unix:/run/php/php8.5-agent.sock;
}

# Everything else → public www pool
location ~ \.php$ {
    include fastcgi.conf;
    fastcgi_split_path_info ^(.+?\.php)(/.*)$;
    fastcgi_param SCRIPT_FILENAME $request_filename;
    fastcgi_pass unix:/run/php/php8.5-fpm.sock;
}
```

## Gotchas worth remembering

- **Container restart wiped my pool tweaks.** The bootstrap copies
  `/etc/php.orig/*` to `/etc/php/` with `cp -rn` (no-clobber). Your
  host-side edits to `pool.d/www.conf` or `agent.conf` survive — but
  if a *new* file shows up in `/etc/php.orig/pool.d/` between image
  versions, it lands in your live tree. Place an empty tombstone file
  at the same path on the host to prevent re-creation.

- **`emergency_restart_threshold` is GLOBAL.** It belongs in
  `php-fpm.conf [global]`, not in any `pool.d/*.conf`. PHP 8.5
  rejects it as an "unknown entry" inside a pool, aborting FPM init
  silently — the container looks like it starts but no workers
  spawn. If you see that error in `docker logs`, look for
  emergency/process-control directives inside a pool.

- **`opcache.validate_timestamps=0` on the agent pool will bite you.**
  When you hot-patch a plugin file via MCP `write-file`, the cached
  opcodes from before the edit are reused. Always `=1` on the agent
  pool. The public pool wants `=0` for perf.

- **Test FPM config before restart.** `php-fpm<ver> -t` validates
  every pool. A single typo aborts the master and takes both pools
  down — there's no "skip broken pool" behaviour.

- **Sockets aren't recreated on `service ... reload`** (SIGUSR2 in
  FPM-speak). Changes to `listen.owner` / `listen.group` /
  `listen.mode` only take effect after a full FPM restart.
