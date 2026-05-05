#!/bin/sh

#
# A snippet I used to migrate 2 repo's into one aptly
#

rm -rf ~/repo
mkdir -p ~/repo/public
mkdir -p /tmp/aptly/main
cd /tmp/aptly/main

#rsync -av -e "ssh -p 22" reprepro@remote-host:/repo/pool/main/ .
rsync -av /repo/pool/main .
for DIST in jammy impish focal bionic bullseye buster stretch bookworm sid;
do
    REPO="${DIST}"
    aptly repo drop ${REPO}
    aptly repo create -distribution=${DIST} -component=main ${REPO}
    rm -rf /tmp/aptly/${DIST}
    mkdir -p /tmp/aptly/${DIST}
    find /tmp/aptly/main -name "*${DIST}*" -exec mv {} /tmp/aptly/${DIST}/ \;
    aptly -architectures=amd64,i386,source,all repo add ${REPO} /tmp/aptly/${DIST}
    rm -rf /tmp/aptly/${DIST}
    aptly -architectures=amd64,i386,source,all publish repo ${REPO} filesystem:${REPO}:.
    aptly -architectures=amd64,i386,source,all publish update ${REPO} filesystem:${REPO}:.
done
rm -rf /tmp/aptly

mkdir -p /tmp/aptly/main
cd /tmp/aptly/main
rsync -av /repo-openssl3/pool/main .

for DIST in impish focal bionic bullseye buster stretch bookworm sid;
do
    REPO="${DIST}-openssl3"
    aptly repo drop ${REPO}
    aptly repo create -distribution=${DIST} -component=main ${REPO}
    rm -rf /tmp/aptly/${DIST}
    mkdir -p /tmp/aptly/${DIST}
    find /tmp/aptly/main -name "*${DIST}*" -exec mv {} /tmp/aptly/${DIST}/ \;
    aptly -architectures=amd64,i386,source,all repo add ${REPO} /tmp/aptly/${DIST}
    rm -rf /tmp/aptly/${DIST}
    aptly -architectures=amd64,i386,source,all publish repo ${REPO} filesystem:${REPO}:.
    aptly -architectures=amd64,i386,source,all publish update ${REPO}} filesystem:${REPO}:.
done

