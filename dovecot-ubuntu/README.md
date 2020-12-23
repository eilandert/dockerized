dockerized dovecot+sieve image based on ubuntu:rolling

Mount /etc/dovecot for configfiles, if dovecot.conf does not exist all default configfiles will be copied on startup.
Built with dovecot packages on https://launchpad.net/~eilander/+archive/ubuntu/backports
The docker-compose file is on my github https://github.com/eilandert/dockerized/blob/master/dovecot-ubuntu/docker-compose.yml

Environment variable(s):
  SYSLOG_HOST=10.0.0.1
  TZ=Europe/Amsterdam
  DB_DRIVER=mysql
  DB_DATABASE=vimbadmin
  DB_HOST=172.30.0.100
  DB_PORT=3306
  DB_USERNAME=vimbadmin
  DB_PASSWORD=

This docker is loaded with:
  Dovecot and all modules (obviously)
  rspamd (to use rspamd's client rspamc)
  spamc (spamassassin client)
  pyzor 
  razor 
  vimbadmin scripts in /opt/scripts/vimbadmin

Drivers for pgsql are also present.
