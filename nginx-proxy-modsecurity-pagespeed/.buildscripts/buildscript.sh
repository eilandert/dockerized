#!/bin/sh

export FULLPATH="${GITPATH}/nginx-proxy-modsecurity-pagespeed/.buildscripts"

cp ${FULLPATH}/Dockerfile ${GITPATH}/nginx-proxy-modsecurity-pagespeed/Dockerfile
cp ${FULLPATH}/Dockerfile ${GITPATH}/nginx-proxy-modsecurity-pagespeed/Dockerfile-php56
cp ${FULLPATH}/Dockerfile ${GITPATH}/nginx-proxy-modsecurity-pagespeed/Dockerfile-php72
cp ${FULLPATH}/Dockerfile ${GITPATH}/nginx-proxy-modsecurity-pagespeed/Dockerfile-php74
cp ${FULLPATH}/Dockerfile ${GITPATH}/nginx-proxy-modsecurity-pagespeed/Dockerfile-php80
cp ${FULLPATH}/Dockerfile ${GITPATH}/nginx-proxy-modsecurity-pagespeed/Dockerfile-multi

sed -i 's/#FROM#/eilandert\/ubuntu-base:rolling/' ${GITPATH}/nginx-proxy-modsecurity-pagespeed/Dockerfile
sed -i 's/#FROM#/eilandert\/php-fpm:multi/' ${GITPATH}/nginx-proxy-modsecurity-pagespeed/Dockerfile-multi
sed -i 's/#FROM#/eilandert\/php-fpm:5.6/' ${GITPATH}/nginx-proxy-modsecurity-pagespeed/Dockerfile-php56
sed -i 's/#FROM#/eilandert\/php-fpm:7.2/' ${GITPATH}/nginx-proxy-modsecurity-pagespeed/Dockerfile-php72
sed -i 's/#FROM#/eilandert\/php-fpm:7.4/' ${GITPATH}/nginx-proxy-modsecurity-pagespeed/Dockerfile-php74
sed -i 's/#FROM#/eilandert\/php-fpm:8.0/' ${GITPATH}/nginx-proxy-modsecurity-pagespeed/Dockerfile-php80

sed -i 's/bootstrap.sh\ /bootstrap-php.sh\ /' ${GITPATH}/nginx-proxy-modsecurity-pagespeed/Dockerfile-*

if [ "${BUILD}" = "yes" ]; then

    docker build -t eilandert/nginx-modsecurity3-pagespeed:latest -f ${GITPATH}/nginx-proxy-modsecurity-pagespeed/Dockerfile ${GITPATH}/nginx-proxy-modsecurity-pagespeed
    docker build -t eilandert/nginx-modsecurity3-pagespeed:php56 -f ${GITPATH}/nginx-proxy-modsecurity-pagespeed/Dockerfile.php56 ${GITPATH}/nginx-proxy-modsecurity-pagespeed
    docker build -t eilandert/nginx-modsecurity3-pagespeed:php72 -f ${GITPATH}/nginx-proxy-modsecurity-pagespeed/Dockerfile.php72 ${GITPATH}/nginx-proxy-modsecurity-pagespeed
    docker build -t eilandert/nginx-modsecurity3-pagespeed:php74 -f ${GITPATH}/nginx-proxy-modsecurity-pagespeed/Dockerfile.php74 ${GITPATH}/nginx-proxy-modsecurity-pagespeed
    docker build -t eilandert/nginx-modsecurity3-pagespeed:php80 -f ${GITPATH}/nginx-proxy-modsecurity-pagespeed/Dockerfile.php80 ${GITPATH}/nginx-proxy-modsecurity-pagespeed
    docker build -t eilandert/nginx-modsecurity3-pagespeed:multi -f ${GITPATH}/nginx-proxy-modsecurity-pagespeed/Dockerfile.multi ${GITPATH}/nginx-proxy-modsecurity-pagespeed

    docker pushrm eilandert/nginx-modsecurity3-pagespeed -f ${GITPATH}/nginx-proxy-modsecurity-pagespeed/README.md
fi
