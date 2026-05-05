Gitbuild of rspamd

Tag: eilandert/rspamd-git:latest
Built from git-master with ubuntu:rolling,

Tag: eilandert/rspamd-git:release
Built with latest release on ubuntu:rolling

Please bind your local rspamd configdir to /etc/rspamd. If rspamd.conf does not exist the default configuration will be copied to /etc/rspamd.

Environment variable(s): 

      - TZ=Europe/Amsterdam
      - SYSLOG_HOST=10.0.0.118
      - WAIT_FOR_1=redis1:6379
      - WAIT_FOR_2=redis2:6379
      - WAIT_FOR_3=redis3:6379
      - WAIT_FOR_4=redis4:6379
      - WAIT_FOR_5=redis5:6379

You can use unlimitted WAIT_FOR's
