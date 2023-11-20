#!/bin/bash

# This script uses buildx
# To use/update buildx
# git clone https://github.com/docker/buildx && cd buildx && make install

#ssh -p 8889 aptly@192.168.178.11 "~/bin/daily.sh"

docker buildx rm
docker system prune -f -a


# Ensure the push is only initiated on my build machine
if [ "$(uname -n)" == "build" ]; then PUSH="--push"; fi

#generate dockerfiles and prepare other things
./generate.sh

docker buildx create --use

#for BUILD in base-current phpfpm multiphp nginx-quic nginx-php-quic openssh mail db nginx nginx-php apache apache-misc misc
for BUILD in base-current phpfpm multiphp mail db nginx nginx-php apache apache-misc misc
do
    echo "-----------------------------------"
    echo "BUILDING TARGET ${BUILD}"
    docker buildx bake ${PUSH} ${BUILD}
done

docker buildx bake --push debian-phpfpm81bullseye
docker buildx bake --push debian-apache-php81bullseye

docker buildx rm
docker system prune -f -a
