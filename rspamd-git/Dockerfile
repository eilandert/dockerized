FROM ubuntu:devel as build
LABEL maintainer="Thijs Eilander <eilander@myguard.nl>"

COPY bootstrap.sh /bootstrap.sh

RUN	apt -y update \
	&& apt -y upgrade \
	&& apt-get --no-install-recommends -y install apt-utils \
	&& DEBIAN_FRONTEND="noninteractive" apt-get --no-install-recommends -y install \
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
		zlib1g-dev 

RUN	mkdir -p /opt/src \
	&& cd /opt/src \
	&& git clone --recursive https://github.com/rspamd/rspamd.git \
	&& cd rspamd 

COPY    patches/*.patch ./
RUN     for i in *.patch; do printf "\r\nApplying patch ${i%%.*}\r\n"; patch -p1 < $i || exit 1; done
RUN	cd /opt/src/rspamd \
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
	&& rm -rf /usr/local/share/man /usr/local/share/games /usr/local/share/include /usr/local/share/src /usr/local/lib/python3.8 /usr/local/sbin 

#FROM frolvlad/alpine-glibc:alpine-3.12_glibc-2.31
FROM frolvlad/alpine-glibc
LABEL maintainer="Thijs Eilander <eilander@myguard.nl>"

COPY bootstrap.sh /bootstrap.sh

RUN	apk update \
	&& apk upgrade \
	&& apk add --no-cache syslog-ng \
        && apk del alpine-keys apk-tools \
	&& rm -rf /var/cache/apk/* /lib/apk/db /usr/src/* \
	&& addgroup -S -g 1000 _rspamd \
	&& adduser -S -G _rspamd -u 1000 _rspamd \ 
	&& chmod +x /bootstrap.sh

COPY --from=build /usr/local /usr/local
COPY --from=build /lib/x86_64-linux-gnu/libpthread.so.0 /usr/local/lib/rspamd/libpthread.so.0
COPY --from=build /lib/x86_64-linux-gnu/libglib-2.0.so.0 /usr/local/lib/rspamd/libglib-2.0.so.0
COPY --from=build /lib/x86_64-linux-gnu/libc.so.6 /usr/local/lib/rspamd/libc.so.6
COPY --from=build /lib/x86_64-linux-gnu/libluajit-5.1.so.2 /usr/local/lib/rspamd/libluajit-5.1.so.2
COPY --from=build /lib/x86_64-linux-gnu/libpcre.so.3 /usr/local/lib/rspamd/libpcre.so.3
COPY --from=build /lib/x86_64-linux-gnu/libsqlite3.so.0 /usr/local/lib/rspamd/libsqlite3.so.0
COPY --from=build /usr/lib/x86_64-linux-gnu/libicui18n.so.* /usr/local/lib/rspamd/
COPY --from=build /usr/lib/x86_64-linux-gnu/libicuuc.so.* /usr/local/lib/rspamd/
COPY --from=build /usr/lib/x86_64-linux-gnu/libicudata.so.* /lib/x86_64-linux-gnu/
COPY --from=build /lib/x86_64-linux-gnu/libssl.so.1.1 /usr/local/lib/rspamd/libssl.so.1.1
COPY --from=build /lib/x86_64-linux-gnu/libcrypto.so.1.1 /usr/local/lib/rspamd/libcrypto.so.1.1
COPY --from=build /lib/x86_64-linux-gnu/libz.so.1 /usr/local/lib/rspamd/libz.so.1
COPY --from=build /lib/x86_64-linux-gnu/libsodium.so.23 /usr/local/lib/rspamd/libsodium.so.23
COPY --from=build /lib/x86_64-linux-gnu/librt.so.1 /usr/local/lib/rspamd/librt.so.1
COPY --from=build /lib/x86_64-linux-gnu/libm.so.6 /usr/local/lib/rspamd/libm.so.6
COPY --from=build /lib/x86_64-linux-gnu/libstdc++.so.6 /usr/local/lib/rspamd/libstdc++.so.6
COPY --from=build /lib/x86_64-linux-gnu/libgcc_s.so.1 /usr/local/lib/rspamd/libgcc_s.so.1
COPY --from=build /lib64/ld-linux-x86-64.so.2 /lib64/ld-linux-x86-64.so.2
COPY --from=build /lib/x86_64-linux-gnu/libdl.so.2 /lib/x86_64-linux-gnu/libdl.so.2
COPY --from=build /usr/share/ca-certificates/ /usr/share/ca-certificates/
COPY --from=build /etc/ssl /etc/ssl
COPY --from=build /usr/lib/ssl/ /usr/lib/ssl/
COPY --from=build /usr/share/zoneinfo /usr/share/zoneinfo

CMD ["/bootstrap.sh"]

EXPOSE 11332 11333 11334
VOLUME  [ "/var/lib/rspamd" ]
