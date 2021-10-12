#!/bin/bash

# Ensure the push is only initiated on my build machine
if [ "$(uname -n)" == "build" ]; then PUSH="--push"; fi

docker buildx create --use

for BUILD in base-current misc db mail phpfpm nginx apache apache-misc
do
    docker buildx bake ${PUSH} -f buildx.hcl ${BUILD}
done

docker buildx rm
