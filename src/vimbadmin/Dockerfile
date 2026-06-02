# syntax=docker/dockerfile:1.7
# =====================================================================
#  ViMbAdmin  --  Debian / Angie-minimal / PHP-FPM 8.5
# =====================================================================
#  Single-purpose image for the modernised ViMbAdmin fork
#  (https://github.com/eilandert/ViMbAdmin):
#    * FROM eilandert/debian-base (trixie-slim + deb.myguard.nl repo + hardening)
#    * angie-minimal  (no modsecurity/lua/brotli -- the panel is guarded by a
#      native positive-security vhost instead)
#    * php8.5-fpm with only the extensions ViMbAdmin needs
#    * Snuffleupagus with the app's audited vimbadmin-strict ruleset
#  All Angie config lives in one file: angie.conf.
# =====================================================================

FROM    docker.io/eilandert/debian-base:stable

LABEL   org.opencontainers.image.authors="eilandert" \
        org.opencontainers.image.title="ViMbAdmin" \
        org.opencontainers.image.description="ViMbAdmin (modernised fork) on Angie-minimal + PHP-FPM 8.5" \
        org.opencontainers.image.source="https://github.com/eilandert/dockerized" \
        org.opencontainers.image.vendor="MyGuard"

ENV     DEBIAN_FRONTEND=noninteractive \
        PHPVERSION=8.5 \
        INSTALL_PATH=/opt/vimbadmin \
        VIMBADMIN_GIT=https://github.com/eilandert/ViMbAdmin.git

COPY --chmod=0755 bootstrap.sh /bootstrap.sh
COPY    angie.conf            /etc/angie.orig/angie.conf
COPY    vimb_fastcgi.inc      /vimb_fastcgi.inc

RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt,sharing=locked \
    set -eux ;\
    rm -f /etc/apt/apt.conf.d/docker-clean ;\
    # PHP 8.5 from the ondrej mirror on our edge repo; angie + php from
    # deb.myguard.nl (already wired into debian-base).
    echo "deb [trusted=yes] http://edge.deb.myguard.nl:8888/mirror/ondrej-php ${DIST} main" > /etc/apt/sources.list.d/ondrej-php.list ;\
    apt-get update ;\
    apt-get install -y --no-install-recommends \
      angie-minimal \
      php8.5-fpm \
      php8.5-cli \
      php8.5-mysql \
      php8.5-mbstring \
      php8.5-intl \
      php8.5-xml \
      php8.5-gd \
      php8.5-curl \
      php8.5-bcmath \
      php8.5-zip \
      php8.5-gmp \
      php8.5-snuffleupagus \
      git ca-certificates ;\
    # Dedicated unprivileged FPM user (the fork's pool runs as phpfpm; the
    # socket group is www-data so Angie can reach it). ondrej packages don't
    # create this account, so make it here.
    groupadd -r phpfpm 2>/dev/null || true ;\
    useradd  -r -g phpfpm -G www-data -s /usr/sbin/nologin -d /nonexistent phpfpm 2>/dev/null || true ;\
    # ---- fetch the modernised fork + install deps ----------------------
    git clone --depth 1 "${VIMBADMIN_GIT}" "${INSTALL_PATH}" ;\
    cd "${INSTALL_PATH}" ;\
    php -r "copy('https://getcomposer.org/installer','/tmp/c.php');" ;\
    php /tmp/c.php --quiet --install-dir=/usr/local/bin --filename=composer ;\
    rm -f /tmp/c.php ;\
    composer install --prefer-dist --no-dev --no-interaction --optimize-autoloader ;\
    composer clear-cache ;\
    # ---- Snuffleupagus: install the fork's audited ruleset -------------
    install -D -m 0644 "${INSTALL_PATH}/snuffleupagus/vimbadmin-strict.list" \
        /etc/php/8.5/php-snuffleupagus/vimbadmin-strict.list ;\
    # The php8.5-snuffleupagus package already loads the extension via
    # mods-available; we only point it at our ruleset (loaded last via zz-).
    printf 'sp.configuration_file=/etc/php/8.5/php-snuffleupagus/vimbadmin-strict.list\n' \
        > /etc/php/8.5/fpm/conf.d/zz-snuffleupagus.ini ;\
    # ---- PHP-FPM pool: use the fork's hardened pool -------------------
    rm -f /etc/php/8.5/fpm/pool.d/www.conf ;\
    install -D -m 0644 "${INSTALL_PATH}/contrib/php-fpm/vimbadmin.conf" \
        /etc/php/8.5/fpm/pool.d/vimbadmin.conf ;\
    install -d -m 0755 -o phpfpm -g www-data /run/php ;\
    install -d -m 0750 -o phpfpm -g www-data /var/log/php-fpm ;\
    # ---- app config (docker env) -------------------------------------
    cp application/configs/application.ini.dist application/configs/application.ini ;\
    { \
      echo "" ;\
      echo "[docker : production]" ;\
      echo "securitysalt = \"$(php -r 'echo bin2hex(random_bytes(32));')\"" ;\
      echo "resources.smarty.skin = \"dark\"" ;\
    } >> application/configs/application.ini ;\
    # keep a pristine copy for first-run restore (bootstrap)
    cp -rp application/configs application/configs.orig ;\
    chown -R phpfpm:www-data var application/configs ;\
    # ---- prune build-time bits ---------------------------------------
    apt-get -y purge git ;\
    apt-get -y autoremove ;\
    rm -rf "${INSTALL_PATH}/.git" /root/.composer /usr/local/bin/composer \
           /etc/apt/sources.list.d/ondrej-php.list

WORKDIR /opt/vimbadmin
EXPOSE  80 443

HEALTHCHECK --interval=30s --timeout=5s --start-period=15s --retries=3 \
    CMD wait-for-it -t 3 127.0.0.1:80 || exit 1

STOPSIGNAL SIGQUIT
CMD ["/bootstrap.sh"]
