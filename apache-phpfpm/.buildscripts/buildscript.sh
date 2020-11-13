#!/bin/sh

export FULLPATH="${GITPATH}/apache-phpfpm/.buildscripts"

cp ${FULLPATH}/Dockerfile-template ${GITPATH}/apache-phpfpm/Dockerfile-5.6
cp ${FULLPATH}/Dockerfile-template ${GITPATH}/apache-phpfpm/Dockerfile-7.2
cp ${FULLPATH}/Dockerfile-template ${GITPATH}/apache-phpfpm/Dockerfile-7.4
cp ${FULLPATH}/Dockerfile-template ${GITPATH}/apache-phpfpm/Dockerfile-8.0
cp ${FULLPATH}/Dockerfile-template ${GITPATH}/apache-phpfpm/Dockerfile-multi

sed -i 's/#PHPVERSION#/5.6/' ${GITPATH}/apache-phpfpm/Dockerfile-5.6
sed -i 's/#PHPVERSION#/7.2/' ${GITPATH}/apache-phpfpm/Dockerfile-7.2
sed -i 's/#PHPVERSION#/7.4/' ${GITPATH}/apache-phpfpm/Dockerfile-7.4
sed -i 's/#PHPVERSION#/8.0/' ${GITPATH}/apache-phpfpm/Dockerfile-8.0
sed -i 's/#PHPVERSION#/multi/' ${GITPATH}/apache-phpfpm/Dockerfile-multi

sed -i 's/MODE=fpm/MODE=multi/'  ${GITPATH}/apache-phpfpm/Dockerfile-multi
sed -i '/libapache2-mod-php/d'   ${GITPATH}/apache-phpfpm/Dockerfile-multi

if [ "${BUILD}" = "yes" ]; then

  docker build -t eilandert/apache-phpfpm:5.6 -f /opt/dockerized/apache-phpfpm/Dockerfile-5.6 /opt/dockerized/apache-phpfpm \
  && docker build -t eilandert/apache-phpfpm:7.2 -f /opt/dockerized/apache-phpfpm/Dockerfile-7.2 /opt/dockerized/apache-phpfpm \
  && docker build -t eilandert/apache-phpfpm:7.4 -t eilandert/apache-phpfpm:latest -f /opt/dockerized/apache-phpfpm/Dockerfile-7.4 /opt/dockerized/apache-phpfpm \
  && docker build -t eilandert/apache-phpfpm:8.0 -f /opt/dockerized/apache-phpfpm/Dockerfile-8.0 /opt/dockerized/apache-phpfpm \
  && docker build -t eilandert/apache-phpfpm:multi -f /opt/dockerized/apache-phpfpm/Dockerfile-multi /opt/dockerized/apache-phpfpm

fi

docker pushrm eilandert/apache-phpfpm -f ${GITPATH}/apache-phpfpm/README.md

