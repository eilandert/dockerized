# PHP-FPM

An Ubuntu-latest docker with PHP packages from [Ondrej](https://launchpad.net/~ondrej/+archive/ubuntu/php)

A docker I created for serving php content, used as base image for my apache/nginx dockers.

FEATURES:

- Nullmailer for easy mailing from within e.g. wordpress
- Most php-modules from the Ondrej PPA are included
- Daily rebuilds
- composer installed

See [docker-compose.yml](https://github.com/eilandert/dockerized/blob/master/php-fpm/docker-compose.yml) for examples.

TAGS:

- eilandert/php-fpm:latest defaults to 7.4 at this time<BR>
- eilandert/php-fpm:5.6<BR>
- eilandert/php-fpm:7.2<BR>
- eilandert/php-fpm:7.4<BR>
- eilandert/php-fpm:8.0<BR>

Don't use the multi-php image yet, it's primarly built as base image, the startscript does not add up for it yet

TODO

I am open for suggestions..
