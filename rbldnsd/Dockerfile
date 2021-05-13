FROM alpine:3.12.7 as build

RUN apk update && apk upgrade  && apk add git gcc musl-dev pkgconfig zlib-dev zlib-static libev-dev libevent-static make cmake wget

RUN	mkdir -p /opt && cd /opt && \
	git clone https://github.com/rspamd/rbldnsd && \
	cd rbldnsd && \
	sed -i '/.*DEFAULT_LIBRARY_PATHS.*/a set(CMAKE_FIND_LIBRARY_SUFFIXES .a ${CMAKE_FIND_LIBRARY_SUFFIXES})' CMakeLists.txt && \
	CC="gcc -O3 -fPIE -static-pie" cmake . && \
	make && \
	strip rbldnsd-1.0.0 && \
        addgroup -S -g 1000 rbldns && adduser -S -G rbldns -u 1000 rbldns && \
	cd /opt && wget https://raw.githubusercontent.com/eilandert/dockerized/master/rbldnsd/badhosts.zone

FROM scratch

COPY --from=build /etc/passwd /etc/group /etc/
COPY --from=build /opt/rbldnsd/rbldnsd-1.0.0 /opt/rbldnsd
COPY --from=build /opt/badhosts.zone /zones/

CMD ["/opt/rbldnsd","-w","/zones","-b","0.0.0.0/53","-vv","-a", "-f","-n","-q","rbl.mailscreen.nl:ip4set:badhosts.zone"]

EXPOSE 53
