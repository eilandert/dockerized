#!/bin/bash

# This script uses buildx
# To use/update buildx
# git clone https://github.com/docker/buildx && cd buildx && make install


# Ensure the push is only initiated on my build machine
if [ "$(uname -n)" == "build" ]; then PUSH="--push"; fi

#generate dockerfiles and prepare other things
./generate.sh

docker buildx create --use

for BUILD in base-current misc db mail phpfpm nginx apache apache-misc
do
    docker buildx bake ${PUSH} ${BUILD}
done

docker buildx rm
