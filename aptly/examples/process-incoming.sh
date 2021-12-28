#!/bin/bash

#
# Simple example script to process incoming packages, with filesystem endpoints
# 20211224 Thijs Eilander <eilander@myguard.nl>
#

# You should put the files in /aptly/incoming and call this script
#
# Example:
# rsync -av -e "ssh -p 10022" *deb *.changes *buildinfo aptly@192.168.178.2:/repo/incoming/${RANDOM_DIR}
# ssh aptly@192.168.178.2 "DIR=${RANDOM_DIR} CREATE=YES ~/bin/process-incoming.sh bullseye bullseye-myownupdate"
#
# With the CREATE command the bullseye-myownupdates repo will automaticly be created and published if it does not exist yet
#
# Remove (or replace) the filesystem:${REPO}:. parts if you don't use filesystem endpoints in your .aptly.conf
#

DIST=$1
REPO=$2

cd /aptly/incoming/${DIR}

# When create flag is given: if repo doesn't exist, create it silently
if [ -n "${CREATE}" ]; then
    aptly repo create -distribution=${DIST} -component=main ${REPO} 1>/dev/null 2>&1
fi

# Remove all existing packages first before adding new
DEB=$(ls *.deb | sed 's/_\S*//g')
aptly repo remove ${REPO} ${DEB}
aptly -architectures=amd64,i386,source,all publish update ${DIST} filesystem:${REPO}:.

# Add everything from the .changes file
aptly -architectures=amd64,i386,source,all -repo="${REPO}" repo include /aptly/incoming

# When create flag is given: if repo is not published at all, publish it
if [ -n "${CREATE}" ]; then
    aptly -architectures=amd64,i386,source,all publish repo ${REPO} filesystem:${REPO}:. 1>/dev/null 2>&1
fi

# Update repo
aptly -architectures=amd64,i386,source,all publish update ${DIST} filesystem:${REPO}:.

rm -rf /aptly/incoming/${DIR}

if [ -f "/aptly/bin/dbcleanupcounter.sh" ];
then
    /aptly/bin/dbcleanupcounter.sh
elif [ -f "/aptly/examples/dbcleanupcounter.sh" ];
then
    /aptly/examples/dbcleanupcounter.sh
fi
