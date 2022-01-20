#!/bin/bash

DEB=$1

for REPO in jammy impish focal bionic stretch buster bullseye bookworm sid \
 impish-openssl3 focal-openssl3 bionic-openssl3 stretch-openssl3 buster-openssl3 bullseye-openssl3 bookworm-openssl3 sid-openssl3; 
do
aptly repo remove ${REPO} ${DEB}
aptly -architectures=amd64,i386,source,all publish update ${DIST} filesystem:${REPO}:.

done

aptly db cleanup
