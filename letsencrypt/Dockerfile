FROM alpine:edge
LABEL maintainer="Thijs Eilander <eilander@myguard.nl>"

RUN apk update && apk upgrade && apk add --no-cache certbot tzdata \
	&& apk del alpine-keys apk-tools \
	&& rm -rf /var/cache/apk/* /lib/apk/db /usr/src/* 

CMD ["certbot","renew"]

