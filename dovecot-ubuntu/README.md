dockerized dovecot+sieve image based on ubuntu:rolling or debian:stable

Mount /etc/dovecot for configfiles, if dovecot.conf does not exist all default configfiles will be copied on startup.

Built with dovecot packages on https://launchpad.net/~eilander/+archive/ubuntu/backports

The docker-compose file is on my github https://github.com/eilandert/dockerized/blob/master/dovecot-ubuntu/docker-compose.yml

Tags:
eilandert/dovecot:ubuntu 
eilandert/dovecot:debian
eilandert/dovecot:alpine (without the loaded stuff as stated below)

Environment variable(s) and examples:<BR>
  SYSLOG_HOST=10.0.0.1<BR>
  TZ=Europe/Amsterdam<BR>
  DB_DRIVER=mysql<BR>
  DB_DATABASE=vimbadmin<BR>
  DB_HOST=172.30.0.100<BR>
  DB_PORT=3306<BR>
  DB_USERNAME=vimbadmin<BR>
  DB_PASSWORD=secret<BR>
  USE_VIMBADMIN=yes<BR>

This docker is loaded with:<BR>
  Dovecot and all modules (obviously)<BR>
  rspamd (to use rspamd's client rspamc for reporting spam)<BR>
  spamc (spamassassin client for reporting spam)<BR>
  pyzor (for reporting spam)<BR> 
  razor (for reporting spam)<BR>
  vimbadmin scripts in /opt/scripts/vimbadmin<BR>
<BR>
Drivers for pgsql are also present.
