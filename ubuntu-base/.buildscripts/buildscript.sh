#!/bin/sh


cp ${GITPATH}/ubuntu-base/.buildscripts/Dockerfile-template ${GITPATH}/ubuntu-base/Dockerfile-devel
cp ${GITPATH}/ubuntu-base/.buildscripts/Dockerfile-template ${GITPATH}/ubuntu-base/Dockerfile-lts
cp ${GITPATH}/ubuntu-base/.buildscripts/Dockerfile-template ${GITPATH}/ubuntu-base/Dockerfile-rolling

sed -i 's/#TEMPLATE1#/ubuntu:devel/'   ${GITPATH}/ubuntu-base/Dockerfile-devel
sed -i 's/#TEMPLATE1#/ubuntu:latest/'  ${GITPATH}/ubuntu-base/Dockerfile-lts
sed -i 's/#TEMPLATE1#/ubuntu:rolling/' ${GITPATH}/ubuntu-base/Dockerfile-rolling


if [ "${BUILD}" = "yes" ]; then

    docker build -t eilandert/ubuntu-base:lts -f ${GITPATH}/ubuntu-base/Dockerfile-lts ${GITPATH}/ubuntu-base \
        && docker build -t eilandert/ubuntu-base:latest -t eilandert/ubuntu-base:rolling -f ${GITPATH}/ubuntu-base/Dockerfile-rolling ${GITPATH}/ubuntu-base \
        && docker build -t eilandert/ubuntu-base:devel -f ${GITPATH}/ubuntu-base/Dockerfile-devel ${GITPATH}/ubuntu-base

    docker pushrm eilandert/ubuntu-base -f ${GITPATH}/ubuntu-base/README.md


fi
