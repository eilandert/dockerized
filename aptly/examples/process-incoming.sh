#!/bin/bash

#
# Simple example script to process incoming packages, with filesystem endpoints
# 20211224 Thijs Eilander <eilander@myguard.nl>
#

#
# You should upload the packages to /aptly/incoming/${RANDOM_DIR} and call this script via ssh on the buildhost
#
# Example:
# SPKG="nginx"
# RANDOM_DIR=$(mktemp -u | sed 's/\/tmp\/tmp\.//g')
# rsync -v -e "ssh -p 10022" *deb *.changes *buildinfo aptly@192.168.178.2:~/incoming/${RANDOM_DIR}
# ssh aptly@192.168.178.2 "SPKG=${SPKG} DIR=${RANDOM_DIR} CREATE=YES DELETE=YES ~/bin/process-incoming.sh bullseye bullseye-myownupdate"
#
# With the CREATE command the bullseye-myownupdates repo will automaticly be created and published if it does not exist yet
# The DELETE command deletes the package(s) first before adding.
#
# Remove (or replace) the filesystem:${REPO}:. parts if you don't use filesystem endpoints in your .aptly.conf
#

#Set some personal defaults, comment it to use on cmdline
DELETE=YES
CREATE=YES

# Sanitize variables..
if [ -z "${DIST}" ]; then DIST="$1"; fi
if [ -z "${REPO}" ]; then REPO="$2"; fi
if [ ! "${CREATE}" == "YES" ]; then unset CREATE; fi
if [ ! "${DELETE}" == "YES" ]; then unset DELETE; fi

# if DIR is given and starts with /tmp, honor that, else append it to /aptly/incoming
if [[ ! ${DIR} =~ ^\/tmp/ ]]; then
    DIR="/aptly/incoming/${DIR}"
fi

echo "------------------------------------"
echo "Processing: ${SPKG}"
echo "DIST=${DIST}"
echo "REPO=${REPO}"
echo "DELETE=${DELETE}"
echo "CREATE=${CREATE}"
echo "DIR=${DIR}"
echo "------------------------------------"

cd ${DIR}

# When create flag is given: try to create the repo silently.
if [ "${CREATE}" == "YES" ]; then
    aptly repo create -distribution=${DIST} -component=main ${REPO} 1>/dev/null 2>&1
fi

if [ "${DELETE}" == "YES" ]; then
    # The following block might be overkill and not needed...
    # I created it because there were some leftovers after disabling a subpackage
    # Also, I couldn't be "creative" with version numbers on my testing instance of aptly

    # if SPKG is defined, delete the complete package+subpackages
    if [ -n "${SPKG}" ]; then
        echo "Removing ${SPKG}"
        aptly repo remove ${REPO} "\$Source ($SPKG)"
    else
        # Remove the existing package first before adding the new one
        DEB=$(ls *.deb | sed 's/_\S*//g')
        aptly repo remove ${REPO} ${DEB}
    fi
    # Update repo to reflect the changes of deletion
    aptly -architectures=amd64,i386,source,all publish update ${DIST} filesystem:${REPO}:.
fi

# Add everything from the .changes file
aptly -architectures=amd64,i386,source,all -repo="${REPO}" -force-replace repo include ${DIR}

# When create flag is given: if repo is not published yet, publish it
if [ "${CREATE}" == "YES" ]; then
    aptly -architectures=amd64,i386,source,all publish repo ${REPO} filesystem:${REPO}:. 1>/dev/null 2>&1
fi

# Update repo
aptly -architectures=amd64,i386,source,all publish update ${DIST} filesystem:${REPO}:.

cd ~
rm -rf ${DIR}

if [ ! -d /aptly/incoming ]; then
    mkdir -p /aptly/incoming
fi

if [ -f "/aptly/bin/dbcleanupcounter.sh" ];
then
    /aptly/bin/dbcleanupcounter.sh
elif [ -f "/aptly/examples/dbcleanupcounter.sh" ];
then
    /aptly/examples/dbcleanupcounter.sh
fi
