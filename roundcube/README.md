
THIS DOCKER IS WORKING IN PROGRESS, PLEASE REPORT IF SOMETHING DOESN'T WORK

Daily rebuild of roundcube based on [eilandert/apache-phpfpm:7.4](https://hub.docker.com/r/eilandert/apache-phpfpm)
(ubuntu:rolling with [Apache2](https://launchpad.net/~eilander/+archive/ubuntu/apache2) and [PHP](https://launchpad.net/~ondrej/+archive/ubuntu/php))

Designed to be behind an [(nginx) reverse proxy](https://hub.docker.com/r/eilandert/nginx-modsecurity3-pagespeed), but all functionality is there to do what you want.

Mount /var/roundcube/config inside the docker to get to some extra configuration options

See [docker-compose](https://github.com/eilandert/dockerized/blob/master/roundcube/docker-compose.yml) for examples

I'll try to maintain compatability with the official [roundcube](https://hub.docker.com/r/roundcube/roundcubemail) image. Let me know it something doesn't work!
