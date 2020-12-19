Daily rebuild of roundcube based on [eilandert/apache-phpfpm:8.0](https://hub.docker.com/r/eilandert/apache-phpfpm)
(ubuntu:rolling with [Apache2](https://launchpad.net/~eilander/+archive/ubuntu/apache2) and [PHP](https://launchpad.net/~ondrej/+archive/ubuntu/php))

Designed to be behind a [(nginx) reverse proxy](https://hub.docker.com/r/eilandert/nginx-modsecurity3-pagespeed), but all functionality is there to do what you want.

Tags:<BR>
eilandert/roundcube:php7.4 (roundcube stable + php7.4)<BR>
eilandert/roundcube:php8.0 (roundcube git + php8.0 (unstable))<BR>
eilandert/roundcube:latest -> defaults to php7.4<BR>

Extra plugins and skins provided.

Mount /var/roundcube/config inside the docker to get to the configuration options about roundcube,phpfpm and apache<BR>
Mount /var/www/html/plugins if you want to edit plugin configs<BR>
Mount /etc/apache2 and /etc/php if you need more control.<BR>
(directory contents will be copied with the default configs when the dir is empty)

Extra environmentsetting (on top of the official image):
- CLEAN_INACTIVE_USERS_DAYS=365   (clean inactive users after x days)
- TZ  (example TZ=Europe/Amsterdam)

See [docker-compose](https://github.com/eilandert/dockerized/blob/master/roundcube/docker-compose.yml) for examples

I'll try to maintain compatibility with the official [roundcube](https://hub.docker.com/r/roundcube/roundcubemail) image so you can always switch back by changing the docker tag. 
Let me know it something doesn't work!

Added plugins:<BR>
- https://github.com/corbosman/message_highlight<BR>
- https://github.com/dsoares/roundcube-rcguard<BR>
- https://github.com/filhocf/roundcube-attachment_position<BR>
- https://github.com/filhocf/roundcube-html5_notifier<BR>
- https://github.com/johndoh/roundcube-contextmenu<BR>
- https://github.com/johndoh/roundcube-swipe<BR>
- https://github.com/messagerie-melanie2/Roundcube-Plugin-Infinite-Scroll<BR>
- https://github.com/mike-kfed/rcmail-thunderbird-labels<BR>
- https://github.com/random-cuber/contextmenu_folder<BR>
- https://github.com/random-cuber/responses<BR>
- https://github.com/texxasrulez/advanced_search<BR>
- https://github.com/texxasrulez/persistent_login<BR>
- https://github.com/texxasrulez/roundcube_fail2ban<BR>
- https://github.com/thomascube/roundcube-elastic4mobile<BR>

Added skins:<BR>
- https://github.com/EstudioNexos/mabola-blue<BR>
- https://github.com/filhocf/mabola<BR>
- https://github.com/filhocf/roundcube-chameleon<BR>
- https://github.com/filhocf/roundcube-chameleon-blue<BR>

