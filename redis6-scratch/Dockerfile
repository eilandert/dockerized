FROM alpine:latest as build

# add our user and group first to make sure their IDs get assigned consistently, regardless of whatever dependencies get added
RUN apk update && apk upgrade && addgroup -S -g 1000 redis && adduser -S -G redis -u 999 redis 
# alpine already has a gid 999, so we'll use the next id

#ENV REDIS_DOWNLOAD_URL http://download.redis.io/redis-stable.tar.gz

RUN set -eux; \
	\
	apk add --no-cache --virtual .build-deps \
		coreutils \
		gcc \
		linux-headers \
		make \
		musl-dev \
		openssl-dev \
		curl \
		py-pip \
	;\
	\
	pip install lastversion ;\
#	LASTVERSION=$(lastversion --pre redis https://github.com/redis/redis) ;\
	DOWNLOADURL=$(lastversion --source --pre redis https://github.com/redis/redis) ;\
	mkdir -p /usr/src/redis ;\
	cd /usr/src ;\
	curl -L ${DOWNLOADURL} | tar xz --strip-components=1 -C redis ;\
	\
# disable Redis protected mode [1] as it is unnecessary in context of Docker
# (ports are not automatically exposed when running inside Docker, but rather explicitly by specifying -p / -P)
# [1]: https://github.com/antirez/redis/commit/edd4d555df57dc84265fdfb4ef59a4678832f6da
	grep -E '^ *createBoolConfig[(]"protected-mode",.*, *1 *,.*[)],$' /usr/src/redis/src/config.c ;\
	sed -ri 's!^( *createBoolConfig[(]"protected-mode",.*, *)1( *,.*[)],)$!\10\2!' /usr/src/redis/src/config.c ;\
	grep -E '^ *createBoolConfig[(]"protected-mode",.*, *0 *,.*[)],$' /usr/src/redis/src/config.c ;\
# for future reference, we modify this directly in the source instead of just supplying a default configuration flag because apparently "if you specify any argument to redis-server, [it assumes] you are going to specify everything"
# see also https://github.com/docker-library/redis/issues/4#issuecomment-50780840
# (more exactly, this makes sure the default behavior of "save on SIGTERM" stays functional by default)
	export BUILD_TLS=yes; \
	make CFLAGS="-static" EXEEXT="-static" LDFLAGS="-I/usr/local/include/" -C /usr/src/redis -j "$(nproc)" all; \
	make PREFIX="/opt" -C /usr/src/redis install; \
	cd /opt/bin && rm redis-benchmark redis-check-aof redis-check-rdb;\
	cd /opt/bin && ln -s redis-server redis-check-aof && ln -s redis-server redis-check-rdb;\
	strip --strip-all /opt/bin/* ;\
	strip --strip-all /lib/*so.1* ;\
	mkdir /data && chown 1000:999 /data ;\
	mkdir /config 

#FROM scratch
FROM busybox:musl

COPY --from=build /etc/passwd /etc/group /etc/
COPY --from=build /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/
COPY --from=build /lib/ld-musl-*.so.1 /lib/
COPY --from=build /lib/libcrypto.so.1.1 /lib/
COPY --from=build /lib/libssl.so.1.1 /lib/
COPY --from=build /config /config
COPY --from=build /opt/ /usr/
COPY --from=build --chown=999:1000 /data /data

VOLUME ["/data"]

CMD ["/usr/bin/redis-server"]

EXPOSE 6379
