#!/bin/bash

ssh aptly@192.168.178.11 -p 8889 /aptly/scripts/daily.sh

echo `date` > /tmp/dockerized.lastrun


# This script uses buildx
# To use/update buildx
# git clone https://github.com/docker/buildx && cd buildx && make install

docker buildx rm
docker system prune -f -a


# Ensure the push is only initiated on my build machine
if [ "$(uname -n)" == "build" ]; then PUSH="--push"; fi

#generate dockerfiles and prepare other things
./generate.sh

docker buildx create --use

#removed angie and angiephp  22-9-2025
#base-current phpfpm multiphp nginx-php nginx angie-php angie mail db apache apache-misc misc

#for BUILD in base-current phpfpm multiphp nginx-quic nginx-php-quic openssh mail db nginx nginx-php apache apache-misc misc
for BUILD in \
noble \
trixy \
rolling \
ubuntu-phpfpm56 \
debian-phpfpm56 \
ubuntu-phpfpm72 \
debian-phpfpm72 \
ubuntu-phpfpm74 \
debian-phpfpm74 \
ubuntu-phpfpm80 \
debian-phpfpm80 \
ubuntu-phpfpm81 \
debian-phpfpm81 \
ubuntu-phpfpm82 \
debian-phpfpm82 \
ubuntu-phpfpm83 \
debian-phpfpm83 \
ubuntu-multiphp \
debian-multiphp \
debian-nginx \
ubuntu-nginx \
debian-angie \
ubuntu-angie \
debian-angie-php56 \
debian-angie-php72 \
debian-angie-php74 \
debian-angie-php80 \
debian-angie-php81 \
debian-angie-php82 \
debian-angie-php83 \
debian-angie-multi \
ubuntu-nginx-php56 \
debian-nginx-php56 \
ubuntu-nginx-php72 \
debian-nginx-php72 \
ubuntu-nginx-php74 \
debian-nginx-php74 \
ubuntu-nginx-php80 \
debian-nginx-php80 \
ubuntu-nginx-php81 \
debian-nginx-php81 \
ubuntu-nginx-php82 \
debian-nginx-php82 \
ubuntu-nginx-php83 \
debian-nginx-php83 \
ubuntu-nginx-multi \
debian-nginx-multi \
debian-apache-php56 \
debian-apache-php72 \
debian-apache-php74 \
debian-apache-php80 \
debian-apache-php81 \
debian-apache-php82 \
debian-apache-php83 \
debian-apache-multiphp \
ubuntu-apache-php56 \
ubuntu-apache-php72 \
ubuntu-apache-php74 \
ubuntu-apache-php80 \
ubuntu-apache-php81 \
ubuntu-apache-php82 \
ubuntu-apache-php83 \
ubuntu-apache-multiphp \
debian-roundcube \
debian-vimbadmin \
ubuntu-vimbadmin \
ubuntu-postfix \
debian-postfix \
alpine-rspamd \
debian-rspamd-git \
debian-rspamd \
debian-rspamd-official \
ubuntu-rspamd \
ubuntu-dovecot \
debian-dovecot \
ubuntu-redis \
debian-redis \
ubuntu-valkey \
debian-valkey \
ubuntu-mariadb \
debian-mariadb \
clamav \
alpine-letsencrypt \
rbldnsd \
ubuntu-reprepro \
debian-sitewarmup \
alpine-unbound \
aptly \
debian-openssh;
do
    echo "-----------------------------------"
    echo "BUILDING TARGET ${BUILD}"
    docker buildx bake ${PUSH} ${BUILD}
done


docker buildx rm
docker system prune -f -a
