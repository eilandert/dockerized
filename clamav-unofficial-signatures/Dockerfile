FROM alpine:edge
LABEL maintainer="Thijs Eilander <eilander@myguard.nl>"

COPY config.orig /config.orig
COPY bootstrap.sh /bootstrap.sh
COPY check.sh /check.sh

RUN apk add --no-cache bash clamav wget clamav-libunrar curl bind-tools rsync \   
  && apk update && apk upgrade \
  && rm -rf /var/cache/apk/* /usr/src/* \
  && mkdir -p /run/clamav \
  && chown clamav:clamav -R /run/clamav \
  && chown clamav:clamav -R /var/lib/clamav \
  && rm -rf /var/cache/apk/* /usr/src/* \
  && mkdir -p /usr/local/sbin/ \
  && curl -s https://raw.githubusercontent.com/extremeshok/clamav-unofficial-sigs/master/clamav-unofficial-sigs.sh -o /usr/local/sbin/clamav-unofficial-sigs \
  && chmod 755 /usr/local/sbin/clamav-unofficial-sigs \
  && chmod +x /bootstrap.sh && chmod +x /check.sh 

EXPOSE 3310/tcp

VOLUME ["/var/lib/clamav"]

CMD ["/bootstrap.sh"]

HEALTHCHECK CMD /check.sh
