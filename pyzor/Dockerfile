FROM alpine:latest
LABEL maintainer="Thijs Eilander <eilander@myguard.nl>"

COPY pyzorsocket.py /pyzorsocket.py

RUN apk update && apk upgrade \
    && apk add --no-cache python3 py-pip && pip install pyzor && apk del py-pip \
#    && echo "5.9.124.53 public.pyzor.org" >> /etc/hosts \
    && rm -rf /var/cache/apk/* /usr/src/* \ && rm -rf /root

EXPOSE 5953
CMD ["python3", "./pyzorsocket.py", "0.0.0.0", "5953"]
