#!/bin/bash

#
# Simple example script to process incoming packages, with filesystem endpoints
# 20211224 Thijs Eilander <eilander@myguard.nl>
#

# You should put the files in /aptly/incoming and call this script
#
# Example:
# scp *.deb *.changes *buildinfo aptly@192.168.178.2:/aptly/incoming
# ssh aptly@192.168.178.2 "/aptly/scripts/process-incoming.sh bullseye bullseye-myownupdates CREATE"
#
# With the CREATE command the bullseye-myownupdates repo will automaticly be created and published if it does not exist yet
#
# Remove (or replace) the filesystem:${REPO}:. parts if you don't use filesystem endpoints in your .aptly.conf
#

DIST=$1
REPO=$2
ARG3=$3

if [ -n "${ARG3}" = "CREATE" ]; then
    CREATE="YES"
fi

# When create flag is given: if repo doesn't exist, create it silently
if [ -n "${CREATE}" ]; then
    aptly repo create -distribution=${DIST} -component=main ${REPO} 1>/dev/null 2>&1
fi

# Remove all existing packages first before adding new
cd /aptly/incoming
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

# to be sure, empty incoming dir
rm -f /aptly/incoming/*

