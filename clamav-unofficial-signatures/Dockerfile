FROM alpine:edge
LABEL maintainer="Thijs Eilander <eilander@myguard.nl>"

COPY config.orig /config.orig
COPY bootstrap.sh /bootstrap.sh
COPY check.sh /check.sh

RUN apk add --no-cache bash clamav wget clamav-libunrar curl bind-tools rsync tzdata \   
  && apk update && apk upgrade \
  && apk del alpine-keys apk-tools \
  && rm -rf /var/cache/apk/* /lib/apk/db /usr/src/* \
  && mkdir -p /run/clamav \
  && chown clamav:clamav -R /run/clamav \
  && chown clamav:clamav -R /var/lib/clamav \
  && mkdir -p /usr/local/sbin/ \
  && curl -s https://raw.githubusercontent.com/extremeshok/clamav-unofficial-sigs/master/clamav-unofficial-sigs.sh -o /usr/local/sbin/clamav-unofficial-sigs \
  && chmod +x /usr/local/sbin/clamav-unofficial-sigs \
  && chmod +x /bootstrap.sh && chmod +x /check.sh 

CMD ["/bootstrap.sh"]
EXPOSE 3310/tcp
VOLUME ["/var/lib/clamav"]
HEALTHCHECK CMD /check.sh
