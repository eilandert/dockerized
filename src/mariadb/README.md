# MariaDB — self-built, hardened, LTS Docker image (Debian & Ubuntu)

`eilandert/mariadb` is a security-hardened **MariaDB** image built from **our own
rebuild of the MariaDB server package**, published on
**[deb.myguard.nl](https://deb.myguard.nl)**. This is *not* a repack of the
official `mariadb` image or the mariadb.org apt repo: the upstream source comes
from the `MariaDB/server` git tree, the `debian/` packaging is a snapshot of
Debian's `mariadb` source, and the result is recompiled with **myguard build
flags** and installed into the image from the deb.myguard.nl repository that the
base image already trusts (signed-by GPG).

It stays current automatically: the package's `build.sh` asks the MariaDB
Foundation REST API for the latest **LTS** point release (currently the
**11.8.x** series) and rebuilds — so the image is **not version-pinned**, it
always carries the newest LTS rebuild from a daily CI/cron run.

The runtime is **drop-in compatible** with the official `mariadb` image: the same
`docker-entrypoint.sh` semantics and the full `MARIADB_*` / `MYSQL_*` environment
variable set, so existing Compose files and init scripts work unchanged.

## What makes this build different

- **Our own source rebuild**, not mariadb.org binaries — recompiled from
  `MariaDB/server` git with Debian packaging and myguard flags.
- **jemalloc linked in** — `-DWITH_JEMALLOC=yes` is *forced* (upstream's `auto`
  silently falls back to glibc malloc). Built against our own
  [deb/jemalloc](https://deb.myguard.nl) build. Lower fragmentation, better
  high-concurrency behaviour.
- **`-march=x86-64-v2` baseline** — tuned beyond generic x86-64 while still
  running on every server CPU from ~2009 onward (see the SIGILL note below).
- **Galera / wsrep stripped** — no clustering bloat in the single-node image.
- **SSD-tuned defaults** shipped as `60-myguard.cnf` (datadir, buffer pool,
  flush behaviour) — sane out of the box, override freely.
- **Ships `mariadb-myguard-tuner`** — a tuning helper for sizing the instance to
  the host.
- **Slimmed + hardened** — no test/dbgsym packages, AppArmor profile and systemd
  units removed (useless in a container), and **all setuid/setgid bits stripped**
  (MariaDB needs none).

## Why run MariaDB in Docker

- **Reproducible database** — the exact same hardened build on every host,
  versioned with the rest of your stack.
- **Pin to a volume, not a host** — data lives in `/var/lib/mysql`; the container
  is replaceable.
- **Isolation + least privilege** — runs non-root (UID/GID 999), capability-
  dropped, and read-only-root-capable. Background:
  [Docker Hardening for Self-Hosters](https://deb.myguard.nl/2026/05/docker-hardening-rootless-readonly-distroless/).

## Tags

| Tag | Base | Notes |
|---|---|---|
| `debian` / `latest` | `eilandert/debian-base:stable` (trixie) | default |
| `ubuntu` | `eilandert/ubuntu-base:rolling` | Ubuntu variant |

Versions are intentionally not pinned in the tag — each pull gets the current LTS
rebuild. Pin by digest if you need byte-for-byte reproducibility.

## Hardened `docker-compose.yml`

```yaml
services:
  mariadb:
    image: eilandert/mariadb:debian        # or :ubuntu / :latest
    restart: unless-stopped
    read_only: true
    user: "999:999"                        # non-root mysql
    cap_drop: [ALL]
    cap_add:
      - CHOWN                              # chown -R mysql:mysql on first init
      - SETUID
      - SETGID
      - DAC_OVERRIDE
    security_opt:
      - no-new-privileges:true
    tmpfs:
      - /run/mysqld                        # socket + pid (read_only root)
    environment:
      - MARIADB_ROOT_PASSWORD_FILE=/run/secrets/mariadb_root
      - MARIADB_DATABASE=appdb
      - MARIADB_USER=appuser
      - MARIADB_PASSWORD_FILE=/run/secrets/mariadb_app
    secrets: [mariadb_root, mariadb_app]
    volumes:
      - mariadb_data:/var/lib/mysql        # package pins datadir here
      - ./initdb.d:/docker-entrypoint-initdb.d:ro   # *.sql / *.sh run on first init
    ports:
      - "127.0.0.1:3306:3306"              # drop entirely if only sibling containers connect
    healthcheck:
      test: ["CMD", "healthcheck.sh", "--su-mysql", "--connect", "--innodb_initialized"]
      interval: 30s
      timeout: 5s
      retries: 3

volumes:
  mariadb_data:

secrets:
  mariadb_root:
    file: ./secrets/mariadb_root
  mariadb_app:
    file: ./secrets/mariadb_app
```

> `3306` is above 1024, so `NET_BIND_SERVICE` is **not** needed. Keep it on
> loopback or an internal network — never expose a database to the public
> internet.

## Environment variables

Drop-in compatible with the official image. Common ones:

| Variable | Purpose |
|---|---|
| `MARIADB_ROOT_PASSWORD` / `…_FILE` / `…_HASH` | set the root password (prefer `_FILE` secrets) |
| `MARIADB_RANDOM_ROOT_PASSWORD=1` | generate one, printed once in the log |
| `MARIADB_ALLOW_EMPTY_ROOT_PASSWORD=1` | dev only, never production |
| `MARIADB_DATABASE` | create a database on first init |
| `MARIADB_USER` + `MARIADB_PASSWORD` / `…_FILE` / `…_HASH` | create an app user |
| `MARIADB_AUTO_UPGRADE` | run `mariadb-upgrade` on start after an image bump |
| `MARIADB_REPLICATION_*`, `MARIADB_MASTER_*` | primary/replica setup |
| `MYSQL_*` aliases | honoured for compatibility |

## First-run behaviour

- `docker-entrypoint.sh` initialises a fresh `/var/lib/mysql` from the
  `MARIADB_*` env on first start; an existing datadir is reused untouched.
- Scripts in `/docker-entrypoint-initdb.d` (`*.sql`, `*.sql.gz`, `*.sh`) run once,
  on first init only.
- Container override `70-container.cnf` sets `skip-name-resolve` and
  `host-cache-size=0` (sibling containers have no rDNS).
- Healthcheck probes via `healthcheck.sh` (mysql socket connect + InnoDB
  initialised) so "container up" actually means "database ready".

## CPU baseline / SIGILL caveat

The build uses `-march=x86-64-v2` (Nehalem/Westmere, 2009+ — needs SSE4.2 +
POPCNT). It runs on every x86-64 server CPU from ~2009 onward. On an older host
`docker run` hits `SIGILL`; rebuild `deb/mariadb/debian/rules` with the `-march=`
line dropped (generic baseline). Do **not** raise to `x86-64-v3`
(Haswell/AVX2) unless your whole fleet is Haswell-or-newer — there are Westmere
Xeon hosts that v3 would `SIGILL` on (verify with
`ld.so --help | grep x86-64-v3`).

## Links

- **Image source / this repo:** https://github.com/eilandert/dockerized/tree/master/src/mariadb
- **Docker Hub:** https://hub.docker.com/r/eilandert/mariadb
- **All Docker images:** https://deb.myguard.nl/nginx-dockerized/
- **Package repo & articles:** https://deb.myguard.nl
- **A faster sibling datastore (cache/sessions):** [Valkey explained — the Redis fork](https://deb.myguard.nl/2026/05/valkey-explained-redis-fork-debian-ubuntu-package/)
- **Docker hardening guide:** https://deb.myguard.nl/2026/05/docker-hardening-rootless-readonly-distroless/
- **Discord:** https://discord.gg/UQNsFg2y
