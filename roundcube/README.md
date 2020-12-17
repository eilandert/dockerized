Daily rebuild of roundcube based on [eilandert/apache-phpfpm:8.0](https://hub.docker.com/r/eilandert/apache-phpfpm)
(ubuntu:rolling with [Apache2](https://launchpad.net/~eilander/+archive/ubuntu/apache2) and [PHP](https://launchpad.net/~ondrej/+archive/ubuntu/php))

Designed to be behind a [(nginx) reverse proxy](https://hub.docker.com/r/eilandert/nginx-modsecurity3-pagespeed), but all functionality is there to do what you want.

Tags:<BR>
eilandert/roundcube:php7.4 (roundcube stable + php7.4)<BR>
eilandert/roundcube:php8.0 (roundcube git + php8.0 (unstable))<BR>
eilandert/roundcube:latest -> defaults to php7.4<BR>

Extra plugins and skins provided.

Mount /var/roundcube/config inside the docker to get to some extra configuration options<BR>
Mount /etc/apache2 and/or /etc/php if you need more performance/finetuning<BR>
(directories will be copied with the default configs when the dir is empty)

Extra environmentsetting (on top of the official image):
- CLEAN_INACTIVE_USERS_DAYS=365   (clean inactive users after x days)

See [docker-compose](https://github.com/eilandert/dockerized/blob/master/roundcube/docker-compose.yml) for examples

I'll try to maintain compatability with the official [roundcube](https://hub.docker.com/r/roundcube/roundcubemail) image. Let me know it something doesn't work!
