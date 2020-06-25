Gitbuild of rspamd 

Build from git-master with ubuntu:devel, but libs and executables copied to an Alpine container. 
Doing this in Ubuntu instead of Alpine due to the absence of Hyperscan in Alpine.

Please bind your local rspamd configdir to /usr/local/etc/rspamd. If rspamd.conf does not exist the default configuration will be copied to /usr/local/etc/rspamd

Environment variable(s): SYSLOG_HOST

