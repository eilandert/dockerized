FROM ghcr.io/linuxserver/baseimage-ubuntu:jammy
LABEL maintainer="Thijs Eilander <eilander@myguard.nl>"
ENV DEBIAN_FRONTEND="noninteractive"
ARG NORDVPN_VERSION=3.14.1

RUN apt-get update -y && \
    apt-get install -y curl iputils-ping libc6 wireguard qrencode jq && \
    curl https://repo.nordvpn.com/deb/nordvpn/debian/pool/main/nordvpn-release_1.0.0_all.deb --output /tmp/nordrepo.deb && \
    apt-get install -y /tmp/nordrepo.deb && \
    apt-get update -y && \
    apt-get install -y nordvpn${NORDVPN_VERSION:+=$NORDVPN_VERSION} && \
    apt-get remove -y nordvpn-release && \
    apt-get autoremove -y && \
    apt-get autoclean -y && \
    rm -rf \
		/tmp/* \
		/var/cache/apt/archives/* \
		/var/lib/apt/lists/* \
		/var/tmp/*

COPY /rootfs /
CMD /bootstrap.sh
