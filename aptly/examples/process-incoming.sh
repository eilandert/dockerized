#!/bin/bash

REPO=$1
CREATE=$2

if [ -n "${CREATE}" ]; then
  aptly repo create -distribution=${REPO} -component=main ${REPO}
fi

cd /aptly/incoming
for DEB in $(ls *deb)
do
  DEB=$(echo ${DEB}|sed s/_.*$//);
  aptly repo remove ${REPO} ${DEB}
done

aptly -architectures=amd64,i386,source,all -repo="${REPO}" repo include /aptly/incoming

if [ -n "${CREATE}" ]; then
  aptly -architectures=amd64,i386,source,all publish repo ${REPO}
fi

aptly -architectures=amd64,i386,source,all publish update ${REPO}

rm -f /aptly/incoming/*

