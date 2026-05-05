#!/bin/sh

docker buildx rm
docker system prune -f -a --volumes

for BUILD in angie-php nginx-php angie nginx
#for BUILD in base-current angie-php angie
do
    echo "-----------------------------------"
    echo "BUILDING TARGET ${BUILD}"
    docker buildx bake --push  ${BUILD}
done

docker buildx rm
docker system prune -f -a --volumes
