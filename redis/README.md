tag eilandert/redis:scratch<BR>
  A staticly compiled redis (6-stable) in an scratch (with busybox) container<BR>
  If you give a second argument (like redis.conf), it will try to read it as configfile.<BR>
  Put your rdb/aof files in /data<BR>
</P>
tag eilandert/redis:ubuntu or eilandert/redis:debian<BR>
  Based on ubuntu:rolling or debian:stable<BR>
  Mount your config at /etc/redis. if /etc/redis/redis.conf doesn't exist, it will created for you<BR>
  Put your rdb/aof files in /var/lib/redis<BR>
</P>
The debian/ubuntu package has been recreated to use the internal dependencies (like jemalloc and lua) instead of the debian ones.
</p>
github: https://github.com/eilandert/dockerized/tree/master/redis<BR>
packages: https://deb.paranoid.nl<BR>
