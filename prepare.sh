#!/bin/sh

    LASTVERSION=$(lastversion --pre roundcube https://github.com/roundcube/roundcubemail/)
    if [ "${LASTVERSION}" == "" ]; then
        echo "LASTVERSION EMPTY"
    else
        echo ${LASTVERSION} > ${GITPATH}/roundcube/.lastversion
    fi

export GITPATH=dockerized

cp ${GITPATH}/base/Dockerfile-template ${GITPATH}/base/Dockerfile-devel
cp ${GITPATH}/base/Dockerfile-template ${GITPATH}/base/Dockerfile-focal
cp ${GITPATH}/base/Dockerfile-template ${GITPATH}/base/Dockerfile-rolling
cp ${GITPATH}/base/Dockerfile-template ${GITPATH}/base/Dockerfile-lts
cp ${GITPATH}/base/Dockerfile-template ${GITPATH}/base/Dockerfile-focal
cp ${GITPATH}/base/Dockerfile-template ${GITPATH}/base/Dockerfile-bionic
cp ${GITPATH}/base/Dockerfile-template ${GITPATH}/base/Dockerfile-xenial
cp ${GITPATH}/base/Dockerfile-template ${GITPATH}/base/Dockerfile-trusty
cp ${GITPATH}/base/Dockerfile-template ${GITPATH}/base/Dockerfile-bullseye
cp ${GITPATH}/base/Dockerfile-template ${GITPATH}/base/Dockerfile-bullseye
cp ${GITPATH}/base/Dockerfile-template ${GITPATH}/base/Dockerfile-stretch

sed -i 's/#TEMPLATE1#/ubuntu:devel/'   ${GITPATH}/base/Dockerfile-devel
sed -i 's/#TEMPLATE1#/ubuntu:latest/'  ${GITPATH}/base/Dockerfile-lts
sed -i 's/#TEMPLATE1#/ubuntu:rolling/' ${GITPATH}/base/Dockerfile-rolling
sed -i 's/#TEMPLATE1#/ubuntu:focal/'   ${GITPATH}/base/Dockerfile-focal
sed -i 's/#TEMPLATE1#/ubuntu:bionic/'  ${GITPATH}/base/Dockerfile-bionic
sed -i 's/#TEMPLATE1#/ubuntu:xenial/'  ${GITPATH}/base/Dockerfile-xenial
sed -i 's/#TEMPLATE1#/ubuntu:trusty/'  ${GITPATH}/base/Dockerfile-trusty
sed -i 's/#TEMPLATE1#/debian:buster-slim/'    ${GITPATH}/base/Dockerfile-buster
sed -i 's/#TEMPLATE1#/debian:bullseye-slim/'  ${GITPATH}/base/Dockerfile-bullseye
sed -i 's/#TEMPLATE1#/debian:stretch-slim/'  ${GITPATH}/base/Dockerfile-stretch

sed -i s/"\#TEMPLATE2\#"/"echo \"deb \[arch=amd64\] http:\/\/deb.paranoid.nl \${VERSION_CODENAME} main\" > \/etc\/apt\/sources.list.d\/deb.paranoid.nl.list"/ ${GITPATH}/base/{Dockerfile-devel,Dockerfile-lts,Dockerfile-rolling,Dockerfile-focal,Dockerfile-bionic,Dockerfile-xenial,Dockerfile-stretch}
sed -i s/"\#TEMPLATE2\#"/"echo \"deb \[arch=amd64\] http:\/\/deb.paranoid.nl trusty main\" > \/etc\/apt\/sources.list.d\/deb.paranoid.nl.list"/ ${GITPATH}/base/Dockerfile-trusty
sed -i s/"\#TEMPLATE2\#"/"echo \"deb \[arch=amd64\] http:\/\/deb.paranoid.nl \${VERSION_CODENAME} main\" > \/etc\/apt\/sources.list.d\/deb.paranoid.nl.list"/ ${GITPATH}/base/Dockerfile-buster
sed -i s/"\#TEMPLATE2\#"/"echo \"deb \[arch=amd64\] http:\/\/deb.paranoid.nl bullseye main\" > \/etc\/apt\/sources.list.d\/deb.paranoid.nl.list"/ ${GITPATH}/base/Dockerfile-bullseye

