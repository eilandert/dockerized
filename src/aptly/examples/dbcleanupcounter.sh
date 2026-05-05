#!/bin/bash

# Simple example script to do a db cleanup on interval
# Include this in your incoming process script
# 20211224 Thijs Eilander <eilander@myguard.nl>


# Don't overwrite docker env variable
if [ ! -n "${CLEANDBCOUNT}" ];
then
    CLEANDBCOUNT=100
fi
echo ${CLEANDBCOUNT} > ~/.cleandbcountmax

# Disable this script with a value of 0 or -1
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
    ~/examples/maintainance.sh
    COUNTER=0
fi

echo "${COUNTER}" > ~/.cleandbcounter
