#!/bin/sh

mkdir -p /tmp/aptly/main
cd /tmp/aptly/main

rsync -av -e "ssh -p 22" reprepro@remote-host:/repo/pool/main/ .

for DIST in jammy impish focal bionic bullseye buster stretch bookworm sid;
do

    sudo -u aptly aptly repo drop ${DIST}
    sudo -u aptly aptly repo create -distribution=${DIST} -component=main ${DIST}

    rm -rf /tmp/aptly/${DIST}
    mkdir -p /tmp/aptly/${DIST}
    find /tmp/aptly/main -name "*${DIST}*" -exec mv {} /tmp/aptly/${DIST}/ \;
    sudo -u aptly aptly repo add ${DIST} /tmp/aptly/${DIST}
    rm -rf /tmp/aptly/${DIST}

    sudo -u aptly aptly publish repo ${DIST}

done

sudo -u aptly aptly db cleanup

