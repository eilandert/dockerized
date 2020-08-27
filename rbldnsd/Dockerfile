FROM alpine:latest as build


RUN apk update && apk upgrade  && apk add git gcc musl-dev pkgconfig zlib-dev libev-dev make cmake wget

RUN	mkdir -p /opt && cd /opt && \
	git clone https://github.com/rspamd/rbldnsd && \
	cd rbldnsd && \
	cmake . && \
	make && \
	strip rbldnsd-1.0.0 && \
        addgroup -S -g 1000 rbldns && adduser -S -G rbldns -u 1000 rbldns && \
	cd /opt && wget https://raw.githubusercontent.com/eilandert/dockerized/master/rbldnsd/badhosts.zone



FROM scratch
#FROM busybox:musl

COPY --from=build /etc/passwd /etc/group /etc/
COPY --from=build /opt/rbldnsd/rbldnsd-1.0.0 /opt/rbldnsd
COPY --from=build /lib/ld-musl-*.so.1 /lib/
COPY --from=build /lib/libz.so.1 /lib/
COPY --from=build /usr/lib/libev.so.4 /usr/lib/
COPY --from=build /opt/badhosts.zone /zones/

CMD ["/opt/rbldnsd","-w","/zones","-b","0.0.0.0/53","-vv","-a", "-f","-n","-q","rbl.mailscreen.nl:ip4set:badhosts.zone"]

EXPOSE 53
