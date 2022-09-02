#!/bin/sh

for DIST in bionic focal impish jammy sid stretch bullseye buster bookworm;
do

    for DEB in `ls | cut -d"_" -f1 | sort | uniq`;
    do
        aptly repo remove ${DIST} $DEB;
    done;

    aptly -architectures=amd64,i386,source,all publish update ${DIST} filesystem:${DIST}:.
done

#do the same for the $DIST-openssl3 distro's
for DIST in bionic focal impish jammy sid stretch bullseye buster bookworm;
do

    for DEB in `ls | cut -d"_" -f1 | sort | uniq`;
    do
        aptly repo remove ${DIST}-openssl3 $DEB;
    done;

    aptly -architectures=amd64,i386,source,all publish update ${DIST} filesystem:${DIST}-openssl3:.
done

aptly db cleanup


