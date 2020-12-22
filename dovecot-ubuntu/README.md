dockerized dovecot+sieve image based on ubuntu:rolling

Mount /etc/dovecot for configfiles, if dovecot.conf does not exist all default configfiles will be copied/

Build with dovecot packages on https://launchpad.net/~eilander/+archive/ubuntu/backports

The docker-compose file is on my github https://github.com/eilandert/dockerized/blob/master/dovecot-ubuntu/docker-compose.yml

Environment variable(s):
SYSLOG_HOST
