#!/bin/sh

. /etc/os-release

echo "---------------------------------------------------------------------------"
echo "this is a dummy bootstrap, this is a base docker and does nothing right now"
echo "---------------------------------------------------------------------------"
echo "      This docker can be found on https://hub.docker.com/u/eilandert"
echo "               and https://github.com/eilandert/dockerized"
echo "             Packages can be found on https://deb.paranoid.nl"
echo "---------------------------------------------------------------------------"
echo "Running on ${PRETTY_NAME}"
echo "---------------------------------------------------------------------------"
echo "This docker will sleep now for 1h before exit"
echo "---------------------------------------------------------------------------"
sleep 1h;

