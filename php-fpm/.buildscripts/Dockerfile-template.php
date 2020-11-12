RUN     apt-get update \
	&& apt-get install -y --no-install-recommends \
                php#PHPVERSION# \
                php#PHPVERSION#-fpm \
                php#PHPVERSION#-apcu \
                php#PHPVERSION#-bcmath \
                php#PHPVERSION#-cli \
                php#PHPVERSION#-curl \
                php#PHPVERSION#-dom \
                php#PHPVERSION#-gd \
                php#PHPVERSION#-igbinary \
                php#PHPVERSION#-imagick \
                php#PHPVERSION#-memcached \
                php#PHPVERSION#-mbstring \
                php#PHPVERSION#-mysql \
                php#PHPVERSION#-opcache \
                php#PHPVERSION#-pgsql \
                php#PHPVERSION#-readline \
                php#PHPVERSION#-redis \
                php#PHPVERSION#-soap \
                php#PHPVERSION#-tidy \
                php#PHPVERSION#-xml \
                php#PHPVERSION#-zip \
        && apt-get -y autoremove && apt-get -y autoclean \
        && rm -rf /var/lib/apt/lists/*


