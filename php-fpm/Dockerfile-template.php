RUN set -x ;\
    apt-get update ;\
    apt-get install -m -y --no-install-recommends \
      php#PHPVERSION# \
      php#PHPVERSION#-fpm \
      php#PHPVERSION#-apcu \
      php#PHPVERSION#-bcmath \
      php#PHPVERSION#-cli \
      php#PHPVERSION#-curl \
      php#PHPVERSION#-dom \
      php#PHPVERSION#-exif \
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
      php#PHPVERSION#-zip ;\
    apt-get -y autoremove && apt-get -y autoclean ;\
    rm -rf /var/lib/apt/lists/*

