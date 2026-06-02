# syntax=docker/dockerfile:1.7
# =====================================================================
#  ViMbAdmin  --  Debian / Angie-minimal / PHP-FPM 8.5
# =====================================================================
#  Single-purpose, hardened image for the modernised ViMbAdmin fork
#  (https://github.com/eilandert/ViMbAdmin):
#    * FROM eilandert/debian-base (trixie-slim + deb.myguard.nl repo + hardening)
#    * angie-minimal  (no modsecurity/lua/brotli -- the panel is guarded by a
#      native positive-security vhost instead)
#    * php8.5-fpm with only the extensions ViMbAdmin needs
#    * Snuffleupagus with the app's audited vimbadmin-strict ruleset
#    * code owned root:root (read-only to the web/php users); only the var/
#      and configs/ volumes are writable -> runs fine with `read_only: true`
#  All Angie config lives in one file: angie.conf.
#  Deploy guide: ./README.md
# =====================================================================

FROM    docker.io/eilandert/debian-base:stable

LABEL   org.opencontainers.image.authors="eilandert" \
        org.opencontainers.image.title="ViMbAdmin" \
        org.opencontainers.image.description="ViMbAdmin (modernised fork) on Angie-minimal + PHP-FPM 8.5" \
        org.opencontainers.image.source="https://github.com/eilandert/dockerized" \
        org.opencontainers.image.url="https://hub.docker.com/r/eilandert/vimbadmin" \
        org.opencontainers.image.vendor="MyGuard"

ENV     DEBIAN_FRONTEND=noninteractive \
        PHPVERSION=8.5 \
        INSTALL_PATH=/opt/vimbadmin \
        VIMBADMIN_GIT=https://github.com/eilandert/ViMbAdmin.git

COPY --chmod=0755 bootstrap.sh /bootstrap.sh

RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt,sharing=locked \
    set -eux ;\
    rm -f /etc/apt/apt.conf.d/docker-clean ;\
    # PHP 8.5 from the ondrej mirror on our edge repo (fleet convention);
    # angie + php-snuffleupagus from the signed deb.myguard.nl repo (debian-base).
    echo "deb [trusted=yes] http://edge.deb.myguard.nl:8888/mirror/ondrej-php ${DIST} main" > /etc/apt/sources.list.d/ondrej-php.list ;\
    apt-get update ;\
    apt-get install -y --no-install-recommends \
      angie-minimal \
      php8.5-fpm php8.5-cli php8.5-mysql php8.5-mbstring php8.5-intl \
      php8.5-xml php8.5-gd php8.5-curl php8.5-bcmath php8.5-zip php8.5-gmp \
      php8.5-apcu \
      php8.5-snuffleupagus \
      bzip2 \
      git ca-certificates ;\
    # Dedicated unprivileged FPM user (pool runs as phpfpm; socket group
    # www-data so Angie can reach it). ondrej packages don't create it.
    groupadd -r phpfpm 2>/dev/null || true ;\
    useradd  -r -g phpfpm -G www-data -s /usr/sbin/nologin -d /nonexistent phpfpm 2>/dev/null || true ;\
    # ---- fetch the modernised fork + install deps ---------------------
    git clone --depth 1 "${VIMBADMIN_GIT}" "${INSTALL_PATH}" ;\
    cd "${INSTALL_PATH}" ;\
    # Composer: verify the installer against the published SHA-384 first.
    php -r "copy('https://getcomposer.org/installer','/tmp/c.php');" ;\
    EXPECTED="$(php -r "copy('https://composer.github.io/installer.sig','/tmp/c.sig'); echo trim(file_get_contents('/tmp/c.sig'));")" ;\
    ACTUAL="$(php -r "echo hash_file('sha384','/tmp/c.php');")" ;\
    [ "${EXPECTED}" = "${ACTUAL}" ] || { echo 'composer installer checksum mismatch' >&2; exit 1; } ;\
    php /tmp/c.php --quiet --install-dir=/usr/local/bin --filename=composer ;\
    composer install --prefer-dist --no-dev --no-interaction --optimize-autoloader ;\
    # ---- Snuffleupagus -----------------------------------------------
    # Keep the ruleset TEMPLATE on a read-only image path. bootstrap copies it
    # into the writable var/ volume and injects a per-deployment secret_key, so
    # /etc stays read-only-friendly. The package already loads the extension
    # via mods-available; we only point FPM at the runtime copy.
    install -D -m 0644 "${INSTALL_PATH}/contrib/snuffleupagus/vimbadmin-strict.list" \
        /usr/share/vimbadmin/vimbadmin-strict.list ;\
    printf 'sp.configuration_file=%s/var/vimbadmin-strict.list\n' "${INSTALL_PATH}" \
        > /etc/php/8.5/fpm/conf.d/zz-snuffleupagus.ini ;\
    # ---- PHP-FPM pool: the fork's hardened pool ----------------------
    rm -f /etc/php/8.5/fpm/pool.d/www.conf ;\
    install -D -m 0644 "${INSTALL_PATH}/contrib/php-fpm/vimbadmin.conf" \
        /etc/php/8.5/fpm/pool.d/vimbadmin.conf ;\
    # Master FPM error_log -> tmpfs path (ondrej default /var/log/php8.5-fpm.log
    # sits on the read-only rootfs).
    sed -i 's#^error_log = .*#error_log = /var/log/php-fpm/fpm.log#' /etc/php/8.5/fpm/php-fpm.conf ;\
    # ---- OPcache: the image code is immutable, so skip stat() on every
    # include (validate_timestamps=0). Pure shared-memory cache (no file_cache)
    # -> read-only rootfs safe. JIT left OFF (no buffer) on purpose: the panel
    # is I/O-bound, JIT buys nothing here and has bitten us elsewhere.
    # (Doctrine maps via XML, not annotations, so docblocks aren't load-bearing;
    # save_comments left at the default 1 as a harmless safe default.)
    { echo 'opcache.enable=1' ;\
      echo 'opcache.enable_cli=0' ;\
      echo 'opcache.memory_consumption=128' ;\
      echo 'opcache.interned_strings_buffer=16' ;\
      echo 'opcache.max_accelerated_files=20000' ;\
      echo 'opcache.validate_timestamps=0' ;\
      echo 'opcache.save_comments=1' ; } \
        > /etc/php/8.5/fpm/conf.d/99-opcache-tuning.ini ;\
    # ---- APCu: persistent Doctrine metadata/query cache (was ArrayCache =
    # per-request only). Anonymous mmap (no mmap_file_mask) -> RO-rootfs safe.
    { echo 'apc.enabled=1' ;\
      echo 'apc.shm_size=64M' ;\
      echo 'apc.enable_cli=0' ; } \
        > /etc/php/8.5/fpm/conf.d/99-apcu-tuning.ini ;\
    # ---- app config template (no secret baked) -----------------------
    cp application/configs/application.ini.dist application/configs/application.ini ;\
    { echo "" ; echo "[docker : production]" ;\
      echo "resources.smarty.skin = \"dark\"" ;\
      echo "resources.doctrine2cache.type = \"ApcuCache\"" ; } \
        >> application/configs/application.ini ;\
    mv application/configs application/configs.orig ;\
    # ---- strip everything the running image doesn't need -------------
    # app cruft + the contrib sources (SP ruleset already installed from there)
    rm -rf "${INSTALL_PATH}/.git" "${INSTALL_PATH}/contrib" \
           "${INSTALL_PATH}/tests" "${INSTALL_PATH}/doc" "${INSTALL_PATH}/docs" \
           "${INSTALL_PATH}/CHANGELOG" "${INSTALL_PATH}"/*.md "${INSTALL_PATH}/.github" ;\
    # vendor docs / tests / VCS / CI metadata
    find "${INSTALL_PATH}/vendor" -type d \( -iname docs -o -iname doc -o -iname test -o -iname tests -o -iname examples -o -iname '.github' \) -prune -exec rm -rf {} + 2>/dev/null || true ;\
    find "${INSTALL_PATH}/vendor" -type f \( -iname '*.md' -o -iname '*.dist' -o -iname 'phpunit*' -o -iname '.gitignore' -o -iname '.gitattributes' \) -delete 2>/dev/null || true ;\
    # composer + build tools no longer needed at runtime
    rm -f /usr/local/bin/composer ;\
    apt-get -y purge git ;\
    apt-get -y autoremove --purge ;\
    apt-get -y clean ;\
    # docs / man / locale / info (belt + braces; debian-base path-excludes most)
    rm -rf /usr/share/doc/* /usr/share/man/* /usr/share/info/* /usr/share/groff/* \
           /usr/share/lintian/* /usr/share/linda/* ;\
    find /usr/share/locale -mindepth 1 -maxdepth 1 -type d ! -name 'en*' -exec rm -rf {} + 2>/dev/null || true ;\
    # ---- remove ALL apt repositories + lists (no apt at runtime) -----
    rm -rf /etc/apt/sources.list /etc/apt/sources.list.d/* /var/lib/apt/lists/* \
           /var/cache/apt/* /root/.composer /root/.cache /tmp/* ;\
    # ---- codebase READ-ONLY to web/php; only var/ + configs writable -
    chown -R root:root "${INSTALL_PATH}" ;\
    chmod -R go-w "${INSTALL_PATH}" ;\
    install -d -m 0750 -o phpfpm -g www-data \
        "${INSTALL_PATH}/var" "${INSTALL_PATH}/var/templates_c" \
        "${INSTALL_PATH}/var/cache" "${INSTALL_PATH}/var/log" \
        "${INSTALL_PATH}/var/bruteforce" "${INSTALL_PATH}/application/configs" ;\
    chown -R phpfpm:www-data "${INSTALL_PATH}/var" "${INSTALL_PATH}/application/configs" ;\
    # ---- strip any leftover setuid/setgid bits ----------------------
    find / -xdev -type f \( -perm -4000 -o -perm -2000 \) -exec chmod -s {} + 2>/dev/null || true

# Our Angie config replaces the package default (copied AFTER install so it
# doesn't collide with the angie-common conffile during dpkg setup).
COPY    angie.conf            /etc/angie/angie.conf

WORKDIR /opt/vimbadmin
EXPOSE  80

HEALTHCHECK --interval=30s --timeout=5s --start-period=15s --retries=3 \
    CMD wait-for-it -t 3 127.0.0.1:80 || exit 1

STOPSIGNAL SIGQUIT
CMD ["/bootstrap.sh"]
