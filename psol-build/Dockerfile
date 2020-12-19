FROM    eilandert/ubuntu-base:bionic
LABEL   maintainer="Thijs Eilander <eilander@myguard.nl>"
ENV     DEBIAN_FRONTEND="noninteractive"
ENV     TZ=Europe/Amsterdam

COPY bootstrap.sh /bootstrap.sh

RUN	chmod +x /bootstrap.sh

CMD     ["/bootstrap.sh"]

WORKDIR /usr/src

