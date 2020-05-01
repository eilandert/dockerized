dockerized dovecot+sieve image based on alpine:edge

On first run, there will be checked if /etc/dovecot/dovecot.conf exists and if needed, the dovecot configs will be copied. Bind /etc/dovecot to a local dir for your configs. If you use your own configs, make sure the logging goes to /dev/stdout for console output.

The docker-compose file is on my github.



