FROM alpine:edge 

COPY bootstrap.sh /bootstrap.sh

RUN apk update && apk upgrade && chmod 755 /bootstrap.sh


CMD ["/bootstrap.sh"]

