# Package list source-of-truth. The generator strips lines per PHP version
# and per distro via build/config.sh:
#   - #removedinphpXY# markers      -> per-version, both distros
#   - PHP_VERSION_MISSING_EXTS      -> per-version, both distros
#   - PHP_UBUNTU_MISSING_EXTS       -> all versions, Ubuntu only
#   - PHP_UBUNTU_MISSING_CUTOFF     -> from cutoff version, Ubuntu only
# Do NOT add bare "#" comments inside the apt list: bash treats the joined
# RUN line as one command and silently drops everything after the first "#".
# dom/exif are NOT separate packages on any supported distro — they are part
# of php<ver>-xml / php<ver>-common, so don't add them back.
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt,sharing=locked \
    set -xe ;\
    apt-get update ;\
    apt-get install -y --no-install-recommends \
      php#PHPVERSION# \
      php#PHPVERSION#-fpm \
      php#PHPVERSION#-apcu \
      php#PHPVERSION#-bcmath \
      php#PHPVERSION#-cli \
      php#PHPVERSION#-curl \
      php#PHPVERSION#-gd \
      php#PHPVERSION#-gmp \
      php#PHPVERSION#-igbinary \
      php#PHPVERSION#-imagick \
      php#PHPVERSION#-imap \
      php#PHPVERSION#-intl \
      #removedinphp80#php#PHPVERSION#-json \
      php#PHPVERSION#-ldap \
      #removedinphp72#php#PHPVERSION#-mcrypt \
      php#PHPVERSION#-memcache \
      php#PHPVERSION#-memcached \
      php#PHPVERSION#-mbstring \
      php#PHPVERSION#-mysql \
      php#PHPVERSION#-opcache \
      php#PHPVERSION#-pspell \
      php#PHPVERSION#-pgsql \
      php#PHPVERSION#-readline \
      #removedinphp74#php#PHPVERSION#-recode \
      php#PHPVERSION#-redis \
      php#PHPVERSION#-soap \
      php#PHPVERSION#-sqlite3 \
      php#PHPVERSION#-tidy \
      php#PHPVERSION#-xml \
      php#PHPVERSION#-zstd \
      php#PHPVERSION#-snuffleupagus \
      php#PHPVERSION#-zip

