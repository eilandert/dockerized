#!/bin/bash

echo "[MARIADB] This docker image can be found on https://hub.docker.com/u/eilandert or https://github.com/eilandert/dockerized"

case ${MALLOC} in
    jemalloc)
        export LD_PRELOAD=/usr/lib/x86_64-linux-gnu/libjemalloc.so.2
        ;;
    mimalloc)
        export LD_PRELOAD=/usr/lib/mimalloc-2.0/libmimalloc-secure-none.so.2.0
        ;;
    none)
        unset LD_PRELOAD
        ;;
    *)
        export LD_PRELOAD=/usr/lib/mimalloc-2.0/libmimalloc-secure-none.so.2.0
        ;;
esac


