A staticly compiled redis (6-stable) in an scratch (with busybox) container

If you give a second argument (like redis.conf), it will try to read it as configfile.

Put your rdb/aof file in /data


See [docker-compose](https://github.com/eilandert/dockerized/blob/master/redis6-scratch/docker-compose.yml) on [my github](https://github.com/eilandert/dockerized) for examples
