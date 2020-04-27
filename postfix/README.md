
dockerized postfix based on alpine:edge

sets the nameserver to environment variable NAMESERVER
added: /etc/postfix/cron.d/ for reload and stuff

If /etc/postfix/main.cf does not exist, all the original configurationfiles will be copied to /etc/postfix
