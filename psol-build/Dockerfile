FROM    eilandert/ubuntu-base:bionic
LABEL   maintainer="Thijs Eilander <eilander@myguard.nl>"
ENV     DEBIAN_FRONTEND="noninteractive"
ENV     TZ=Europe/Amsterdam

COPY bootstrap.sh /bootstrap.sh

RUN	chmod +x /bootstrap.sh

RUN     dpkg-statoverride --remove /usr/bin/sudo
RUN	apt-get update
RUN	apt-get -y install git nano less lsb-release libpcre3-dev zlib1g-dev build-essential unzip uuid-dev webp g++ libssl-dev wget curl sudo python-minimal

CMD     ["/bootstrap.sh"]

WORKDIR /usr/src

