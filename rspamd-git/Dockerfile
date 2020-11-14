FROM eilandert/ubuntu-base:rolling
LABEL maintainer="Thijs Eilander <eilander@myguard.nl>"
ENV     DEBIAN_FRONTEND="noninteractive"

COPY bootstrap.sh /bootstrap.sh

RUN	apt-get -y update \
	&& apt-get --no-install-recommends -y install \
		git \
		cmake \
		build-essential \
		pkg-config \
		tzdata \ 
		ca-certificates \
		libcurl4-openssl-dev \
		libglib2.0-dev \
		libhyperscan-dev \
		libicu-dev \
		libjemalloc-dev \
		libluajit-5.1-dev \ 
                libmagic-dev \
		libpcre2-dev \ 
		libsodium-dev \
		libsqlite3-dev \
		libssl-dev \
		libunwind-dev \
		perl \
		ragel \
		zlib1g-dev \
	&& mkdir -p /opt/src \
	&& cd /opt/src \
	&& git clone --recursive https://github.com/rspamd/rspamd.git \
	&& cd /opt/src/rspamd \
	&& cmake . \
	&& make \
	&& make install \
	&& mkdir -p /usr/local/etc/rspamd/override.d/ \
        && echo 'type = "console";' > /usr/local/etc/rspamd/override.d/logging.inc \
	&& echo 'bind_socket = "*:11334";' > /usr/local/etc/rspamd/override.d/worker-controller.inc \
        && echo 'pidfile = false;' > /usr/local/etc/rspamd/override.d/options.inc \
	&& mv /usr/local/etc/rspamd /usr/local/etc/rspamd.orig \
	&& mkdir -p /var/log/rspamd \
	&& mkdir -p /var/lib/rspamd \
	&& mkdir -p /var/run/rspamd \
	&& mkdir -p /usr/local/var \
	&& rm -rf /usr/local/share/man /usr/local/share/games /usr/local/share/include /usr/local/share/src /usr/local/lib/python3.8 /usr/local/sbin \
	&& rm -rf /opt \
	&& apt-get purge -y \
                git \
                cmake \
                build-essential \
                pkg-config \
                libcurl4-openssl-dev \
                libglib2.0-dev \
                libhyperscan-dev \
                libicu-dev \
                libjemalloc-dev \
                libmagic-dev \
                libpcre2-dev \
                libsodium-dev \
                libsqlite3-dev \
                libssl-dev \
                libunwind-dev \
                perl \
                ragel \
                zlib1g-dev \ 
                libluajit-5.1-dev \
	&& apt-get  --no-install-recommends -y install \
	        libluajit-5.1 \
		libsqlite3-0 \
		libsodium23 \
		libicu67 \
		syslog-ng-core \
        && apt-get -y autoremove \
        && apt-get -y clean autoclean \
        && rm -rf /var/lib/apt/lists/* \
	&& addgroup --force-badname --gid 1000 _rspamd \
	&& useradd --badnames -M -u 1000 -g 1000 -s /sbin/nologin _rspamd \
	&& chmod +x /bootstrap.sh

COPY syslog-ng.conf /etc/syslog-ng


CMD ["/bootstrap.sh"]

EXPOSE 11332 11333 11334
VOLUME  [ "/var/lib/rspamd" ]
