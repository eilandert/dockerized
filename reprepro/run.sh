#!/bin/bash

if [ -d ./dev-volume ]; then
  mkdir dev-volume
fi

if [[ "$(docker ps -a | grep 'wolfetti-reprepro-dev')" != "" ]]; then
  docker stop wolfetti-reprepro-dev
  docker rm wolfetti-reprepro-dev
fi

docker run -d --name wolfetti-reprepro-dev \
  -p 34022:22 \
  -p 34080:80 \
  -v wolfetti-reprepro-dev_data:/repo \
  wolfetti/reprepro
