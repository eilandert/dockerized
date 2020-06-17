FROM ubuntu:focal as build

COPY bootstrap.sh /bootstrap.sh
RUN chmod +x /bootstrap.sh

RUN apt update && apt upgrade 
RUN DEBIAN_FRONTEND="noninteractive" apt-get -y install tzdata
RUN apt install -y git cmake build-essential ragel pkg-config bash \
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

RUN	mkdir -p /opt/src && cd /opt/src && \
	git clone --recursive https://github.com/rspamd/rspamd.git && \
	cd rspamd
COPY    patches/*.patch ./
RUN     for i in *.patch; do printf "\r\nApplying patch ${i%%.*}\r\n"; patch -p1 < $i || exit 1; done
RUN	cd /opt/src/rspamd && cmake . && make && make install
RUN	groupadd _rspamd && useradd _rspamd -g _rspamd && \ 
	mkdir -p /var/log/rspamd && mkdir -p /var/lib/rspamd && mkdir -p /var/run/rspamd && \
	chown _rspamd:_rspamd /var/log/rspamd && \
        chown _rspamd:_rspamd /var/lib/rspamd && \
        chown _rspamd:_rspamd /var/run/rspamd && \
	rm -rf /usr/local/share/man /usr/local/share/games /usr/local/share/include \
	  /usr/local/share/src /usr/local/lib/python3.8 /usr/local/sbin

#CMD ["/bootstrap.sh"]

FROM  busybox:glibc

COPY --from=build /etc/passwd /etc/group /etc/
COPY --from=build /usr/local /usr/local

COPY --from=build --chown=_rspamd:_rspamd /var/log/rspamd /var/log/rspamd
COPY --from=build --chown=_rspamd:_rspamd /var/lib/rspamd /var/lib/rspamd
COPY --from=build --chown=_rspamd:_rspamd /var/run/rspamd /var/run/rspamd

COPY --from=build /lib/x86_64-linux-gnu/libpthread.so.0 /lib/x86_64-linux-gnu/libpthread.so.0
COPY --from=build /lib/x86_64-linux-gnu/libglib-2.0.so.0 /lib/x86_64-linux-gnu/libglib-2.0.so.0
COPY --from=build /lib/x86_64-linux-gnu/libc.so.6 /lib/x86_64-linux-gnu/libc.so.6
COPY --from=build /lib/x86_64-linux-gnu/libluajit-5.1.so.2 /lib/x86_64-linux-gnu/libluajit-5.1.so.2
COPY --from=build /lib/x86_64-linux-gnu/libpcre.so.3 /lib/x86_64-linux-gnu/libpcre.so.3
COPY --from=build /lib/x86_64-linux-gnu/libsqlite3.so.0 /lib/x86_64-linux-gnu/libsqlite3.so.0
COPY --from=build /lib/x86_64-linux-gnu/libicui18n.so.66 /lib/x86_64-linux-gnu/libicui18n.so.66
COPY --from=build /lib/x86_64-linux-gnu/libicuuc.so.66 /lib/x86_64-linux-gnu/libicuuc.so.66
COPY --from=build /lib/x86_64-linux-gnu/libssl.so.1.1 /lib/x86_64-linux-gnu/libssl.so.1.1
COPY --from=build /lib/x86_64-linux-gnu/libcrypto.so.1.1 /lib/x86_64-linux-gnu/libcrypto.so.1.1
COPY --from=build /lib/x86_64-linux-gnu/libz.so.1 /lib/x86_64-linux-gnu/libz.so.1
COPY --from=build /lib/x86_64-linux-gnu/libsodium.so.23 /lib/x86_64-linux-gnu/libsodium.so.23
COPY --from=build /lib/x86_64-linux-gnu/librt.so.1 /lib/x86_64-linux-gnu/librt.so.1
COPY --from=build /lib/x86_64-linux-gnu/libm.so.6 /lib/x86_64-linux-gnu/libm.so.6
COPY --from=build /lib/x86_64-linux-gnu/libstdc++.so.6 /lib/x86_64-linux-gnu/libstdc++.so.6
COPY --from=build /lib/x86_64-linux-gnu/libgcc_s.so.1 /lib/x86_64-linux-gnu/libgcc_s.so.1
COPY --from=build /lib64/ld-linux-x86-64.so.2 /lib64/ld-linux-x86-64.so.2
COPY --from=build /lib/x86_64-linux-gnu/libdl.so.2 /lib/x86_64-linux-gnu/libdl.so.2
COPY --from=build /lib/x86_64-linux-gnu/libicudata.so.66 /lib/x86_64-linux-gnu/libicudata.so.66
COPY --from=build /usr/share/ca-certificates/ /usr/share/ca-certificates/
COPY --from=build /etc/ssl /etc/ssl
COPY --from=build /usr/lib/ssl/ /usr/lib/ssl/
COPY --from=build /usr/share/zoneinfo /usr/share/zoneinfo
COPY --from=build /bootstrap.sh /bootstrap.sh

CMD ["/bootstrap.sh"]

EXPOSE 11332 11333 11334
VOLUME  [ "/var/lib/rspamd" ]

