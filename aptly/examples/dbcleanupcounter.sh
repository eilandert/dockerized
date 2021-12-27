#!/bin/bash

if [ ! -n "${CLEANDBCOUNT}" ];
then
    CLEANDBCOUNT=100
fi
echo ${CLEANDBCOUNT} > ~/.cleandbcountmax

if [ "${CLEANDBCOUNT}" -le 0 ];
then
    return
fi

if [ ! "~/.cleandbcounter" ];
then
    echo "0" > ~/.cleandbcounter
fi

COUNTERMAX=$(cat ~/.cleandbcountmax)
COUNTER=$(cat ~/.cleandbcounter)

let COUNTER=${COUNTER}+1

if [ "${COUNTER}" -ge "${COUNTERMAX}" ];
then
    aptly db cleanup
    COUNTER=0
fi

echo "${COUNTER}" > ~/.cleandbcounter

