FROM alpine:latest
LABEL maintainer="Thijs Eilander <eilander@myguard.nl>"

COPY bootstrap.sh /bootstrap.sh

RUN apk update && apk upgrade && apk add --no-cache certbot tzdata \
        && apk del alpine-keys apk-tools \
        && rm -rf /var/cache/apk/* /lib/apk/db /usr/src/* \
        && chmod 755 /bootstrap.sh

CMD ["/bootstrap.sh"]

