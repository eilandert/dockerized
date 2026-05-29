# MariaDB — myguard build

Container packaging of the MariaDB build maintained at
`/opt/packages/deb/mariadb/` and published to
[deb.myguard.nl](https://deb.myguard.nl). Two image variants:

| Variant       | Base                                | DIST       | apt repo                          |
| ------------- | ----------------------------------- | ---------- | --------------------------------- |
| `mariadb:debian` (= `:latest`) | `eilandert/debian-base:stable`  | `trixie`   | `deb.myguard.nl ${DIST} main`     |
| `mariadb:ubuntu`               | `eilandert/ubuntu-base:rolling` | `resolute` | `deb.myguard.nl ${DIST} main`     |

## What's different from upstream `library/mariadb`

| Area                     | Upstream MariaDB Docker image                  | This image                                                    |
| ------------------------ | ---------------------------------------------- | ------------------------------------------------------------- |
| Source of `mariadb-server` | mariadb.org apt repo, pinned per image tag    | `deb.myguard.nl`, version not pinned (latest LTS rebuild)     |
| Galera / wsrep           | Built in, `mariadb-backup` pulls galera-4      | Stripped (`-DWITH_WSREP=OFF`, no galera-4 dep)                |
| Test/example plugins     | All built and shipped                          | 12 disabled at cmake, others declared `not-installed`         |
| Debug info / dbgsym      | RelWithDebInfo, dbgsym packages produced       | Release build, no `-g`, no dbgsym                             |
| CPU baseline             | Generic x86-64                                 | `-march=x86-64-v2` (Nehalem/Westmere, 2009+)                  |
| Allocator                | Optional `LD_PRELOAD libjemalloc2`             | Linked at build time (`-DWITH_JEMALLOC=yes`), no preload dance |
| Default config           | Upstream defaults (HDD-era, 128M buffer pool)  | Ships `60-myguard.cnf` SSD-tuned: O_DIRECT, io_capacity 2000, lz4 compression, pool-of-threads, slow_query_log @ 1 s |
| Systemd drop-in          | None                                           | `LimitNOFILE=1M`, Memory/IO/TasksAccounting                   |
| Tooling                  | Just `mariadb-server` + `mariadb-backup`       | + `mariadb-myguard-tuner` (config scorecard)                  |
| Container hardening      | minimal                                        | setuid/setgid bits stripped, apparmor/systemd unused-bits dropped, pinned UID/GID 999 |
| `socat`                  | Installed (for Galera SST)                     | Dropped (no Galera)                                           |

## Tags

Built by [docker-bake.hcl](../../docker-bake.hcl) → targets
`debian-mariadb`, `ubuntu-mariadb`:

- `docker.io/eilandert/mariadb:latest`
- `docker.io/eilandert/mariadb:debian`
- `docker.io/eilandert/mariadb:ubuntu`

## Usage

Identical surface to the official `library/mariadb` image — same
`MARIADB_*` / `MYSQL_*` env vars, same `/docker-entrypoint-initdb.d/`
hook directory, same `healthcheck.sh` script (kept verbatim from
upstream so existing wrappers keep working).

```bash
docker run -d --name db \
    -e MARIADB_ROOT_PASSWORD=changeme \
    -v db_data:/var/lib/mysql \
    -p 3306:3306 \
    eilandert/mariadb:latest
```

For a production-shaped setup — secrets instead of plaintext passwords,
dropped capabilities, `no-new-privileges`, tuned ulimits/sysctls, TZ, and
bind-mount layout — copy [`docker-compose.yml`](docker-compose.yml) from
this directory and adjust the marked values. It documents inline which
capabilities MariaDB actually needs (`CHOWN`, `DAC_OVERRIDE`, `FOWNER`,
`SETUID`, `SETGID` — nothing else) and which sysctls are namespaced
(settable per-container) vs. host-only (`vm.max_map_count`,
`fs.aio-max-nr`, THP, `vm.swappiness`).

After start, audit the running config against the myguard tuning
recommendations:

```bash
docker exec -it db mariadb-myguard-tuner
```

## Configuration

Config layers (loaded in order; later wins):
1. `/etc/mysql/mariadb.conf.d/50-server.cnf` — Debian upstream defaults
2. `/etc/mysql/mariadb.conf.d/60-myguard.cnf` — myguard SSD-tuned defaults
3. `/etc/mysql/mariadb.conf.d/70-container.cnf` — `skip-name-resolve`, `host-cache-size=0`
4. `/etc/mysql/mariadb.conf.d/99-*` — your overrides (mount your own here)

Mount your own snippet to override anything:

```bash
docker run … -v ./my-override.cnf:/etc/mysql/mariadb.conf.d/99-local.cnf:ro …
```

## Version policy

This image deliberately does **not** pin a MariaDB version. Each docker
build pulls whatever is current in `deb.myguard.nl`, which is itself
the latest LTS point release that the MariaDB Foundation flagged as
`Stable + Long Term Support` at build time (see
`/opt/packages/deb/mariadb/build.sh`). If you need a specific version,
either pull a dated digest, or build your own image from this context
with the LTS\_MAJOR / point-release of your choice.

## CPU floor

`-march=x86-64-v2` baseline (Nehalem/Westmere, 2009+ — needs SSE4.2 +
POPCNT). Runs on every x86-64 server CPU from ~2009 onward. If a host is
even older, `docker run` hits `SIGILL`; rebuild `deb/mariadb/debian/rules`
with the `-march=` line dropped (generic baseline). Do **not** raise to
`x86-64-v3` (Haswell/AVX2) unless your whole fleet is Haswell-or-newer —
we have Westmere Xeon hosts that v3 would `SIGILL` on (verify a host with
`ld.so --help | grep x86-64-v3`).
