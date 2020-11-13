#!/bin/sh

export FULLPATH="${GITPATH}/php-fpm/.buildscripts/"

cp ${FULLPATH}/Dockerfile-template.php ${FULLPATH}/Dockerfile-template.php56
cp ${FULLPATH}/Dockerfile-template.php ${FULLPATH}/Dockerfile-template.php72
cp ${FULLPATH}/Dockerfile-template.php ${FULLPATH}/Dockerfile-template.php74
cp ${FULLPATH}/Dockerfile-template.php ${FULLPATH}/Dockerfile-template.php80

sed -i 's/#PHPVERSION#/5.6/' ${FULLPATH}/Dockerfile-template.php56
sed -i 's/#PHPVERSION#/7.2/' ${FULLPATH}/Dockerfile-template.php72
sed -i 's/#PHPVERSION#/7.4/' ${FULLPATH}/Dockerfile-template.php74
sed -i 's/#PHPVERSION#/8.0/' ${FULLPATH}/Dockerfile-template.php80

sed -i 's/#php72#//' ${FULLPATH}/Dockerfile-template.php56
sed -i 's/#php74#//' ${FULLPATH}/Dockerfile-template.php56
sed -i 's/#php80#//' ${FULLPATH}/Dockerfile-template.php56
sed -i 's/#php74#//' ${FULLPATH}/Dockerfile-template.php72
sed -i 's/#php80#//' ${FULLPATH}/Dockerfile-template.php72
sed -i 's/#php80#//' ${FULLPATH}/Dockerfile-template.php74

sed -i '/#php/d' ${FULLPATH}/Dockerfile-template.php*

cat ${FULLPATH}/Dockerfile-template.header \
    ${FULLPATH}/Dockerfile-template.php56 \
    ${FULLPATH}/Dockerfile-template.footer > ${GITPATH}/php-fpm/Dockerfile-5.6

cat ${FULLPATH}/Dockerfile-template.header \
    ${FULLPATH}/Dockerfile-template.php72 \
    ${FULLPATH}/Dockerfile-template.footer > ${GITPATH}/php-fpm/Dockerfile-7.2

cat ${FULLPATH}/Dockerfile-template.header \
    ${FULLPATH}/Dockerfile-template.php74 \
    ${FULLPATH}/Dockerfile-template.footer > ${GITPATH}/php-fpm/Dockerfile-7.4

cat ${FULLPATH}/Dockerfile-template.header \
    ${FULLPATH}/Dockerfile-template.php80 \
    ${FULLPATH}/Dockerfile-template.footer > ${GITPATH}/php-fpm/Dockerfile-8.0

cat ${FULLPATH}/Dockerfile-template.header \
    ${FULLPATH}/Dockerfile-template.php56 \
    ${FULLPATH}/Dockerfile-template.php72 \
    ${FULLPATH}/Dockerfile-template.php74 \
    ${FULLPATH}/Dockerfile-template.php80 \
    ${FULLPATH}/Dockerfile-template.footer > ${GITPATH}/php-fpm/Dockerfile-multi

sed -i 's/\&\& rm -rf \/etc\/php\/5.6/#\&\& rm -rf \/etc\/php\/5.6/' ${GITPATH}/php-fpm/Dockerfile-5.6
sed -i 's/\&\& rm -rf \/etc\/php\/7.2/#\&\& rm -rf \/etc\/php\/7.2/' ${GITPATH}/php-fpm/Dockerfile-7.2
sed -i 's/\&\& rm -rf \/etc\/php\/7.4/#\&\& rm -rf \/etc\/php\/7.4/' ${GITPATH}/php-fpm/Dockerfile-7.4
sed -i 's/\&\& rm -rf \/etc\/php\/8.0/#\&\& rm -rf \/etc\/php\/8.0/' ${GITPATH}/php-fpm/Dockerfile-8.0


if [ "${BUILD}" = "yes" ]; then

  docker build -t eilandert/php-fpm:5.6 -f ${GITPATH}/php-fpm/Dockerfile-5.6 ${GITPATH}/php-fpm \
  && docker build -t eilandert/php-fpm:7.2 -f ${GITPATH}/php-fpm/Dockerfile-7.2 ${GITPATH}/php-fpm \
  && docker build -t eilandert/php-fpm:7.4 -t eilandert/php-fpm:latest -f ${GITPATH}/php-fpm/Dockerfile-7.4 ${GITPATH}/php-fpm \
  && docker build -t eilandert/php-fpm:8.0 -f ${GITPATH}/php-fpm/Dockerfile-8.0 ${GITPATH}/php-fpm \
  && docker build -t eilandert/php-fpm:multi -f ${GITPATH}/php-fpm/Dockerfile-multi ${GITPATH}/php-fpm


fi

docker pushrm eilandert/php-fpm -f ${GITPATH}/php-fpm/README.md




