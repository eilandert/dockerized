FROM alpine:edge

LABEL maintainer "Thijs Eilander <eilander@myguard.nl>"

COPY bootstrap.sh /bootstrap.sh

RUN  apk update && apk upgrade 
RUN  apk add --no-cache dovecot dovecot-lmtpd dovecot-sql dovecot dovecot-pigeonhole-plugin dovecot-pop3d rspamd-client ca-certificates tzdata openssl \
     && rm -rf /var/cache/apk/* /usr/src/* && chmod +x /bootstrap.sh \
     && mv /etc/dovecot /etc/dovecot.orig

EXPOSE 24 143 110 993 995 4190

CMD [ "/bootstrap.sh" ]

