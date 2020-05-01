FROM alpine:edge
LABEL maintainer="Thijs Eilander <eilander@myguard.nl>"

COPY bootstrap.sh /bootstrap.sh
RUN apk update && apk upgrade && apk add --no-cache postfix postfix-pcre postfix-mysql ca-certificates tzdata dcron openssl

RUN     echo "maillog_file=/var/log/mail.log" >> /etc/postfix/main.cf \
        && rm -rf /var/cache/apk/* /usr/src/* && chmod +x /bootstrap.sh \
        && mkdir -p /etc/postfix/cron.d/hourly && mkdir -p /etc/postfix/cron.d/daily \
        && echo "#!/bin/sh" > /etc/postfix/cron.d/daily/reload.sh && chmod +x /etc/postfix/cron.d/daily/reload.sh \
        && echo "postfix reload" >> /etc/postfix/cron.d/daily/reload.sh \
        && mv /etc/postfix /etc/postfix.orig

CMD [ "/bootstrap.sh" ]

EXPOSE 25 587

VOLUME [ "/var/log/" ]
