# Apache + PHP-FPM

A docker I created for serving wordpress, opencart and magento behind a reverse nginx proxy, but all functionality is there so you should be able to use it any way you want

An Ubuntu:rolling (or debian:stable) docker with PHP packages from [Ondrej](https://launchpad.net/~ondrej/+archive/ubuntu/php)

This docker can be found on [Github](https://github.com/eilandert/dockerized/tree/master/apache-phpfpm) and [Dockerhub](https://hub.docker.com/r/eilandert/apache-phpfpm)

Complete Apache packages are on my own [repo](https://launchpad.net/~eilander/+archive/ubuntu/apache2)

Bind /etc/php and /etc/apache2 for configfiles, those dirs will be populated if they are empty


Features:

- Updated rebuild and backport of the Ubuntu-20.10 Groovy Apache2 Package
- Apache compiled with -O3 -flto to squeeze some extra % performance.
- Linked apache against against OpenSSL 1.1.1h so there is ALPN and TLS1.3 support
- Nullmailer for easy mailing from within e.g. wordpress
- Latest Composer installed
- Automatic population of /etc/apache2 /etc/php and /etc/nullmailer if configs are not found (e.g. first run on mounted empty dir)
- Most php-modules from the Ondrej PPA are included
- Daily rebuilds of the docker
- Daily reload of configs when mod_ssl is enabled (for reloading e.g. letsencrypt certificates)


ENVIRONMENT:

- use CACHE=yes to enable apache caching
- use TZ=Europe/Amsterdam (for example) to set timezone
- MALLOC=jemalloc or mimalloc or none (default: jemalloc)
- variables A2ENMOD A2DISMOD A2ENCONF A2DISCONF (changes are persistent if you mount /etc/apache2)
- use MODE=MOD for using mod_php instead of php-fpm. Apache2 will be set to mpm_prefork.
- in multimode (tag :multi) set PHP56=YES PHP72=YES PHP74=YES PHP80=YES to enable specific versions.
- in multimode (tag: multi) you have to create the handler per vhost manually, examples in apache2/conf-available/php\*-fpm.conf

See [docker-compose.yml](https://github.com/eilandert/dockerized/blob/master/apache-phpfpm/docker-compose.yml) for examples.

TAGS:
Ubuntu:
- eilandert/apache-phpfpm:latest defaults to 7.4 at this time
- eilandert/apache-phpfpm:multi for all php versions
- eilandert/apache-phpfpm:5.6
- eilandert/apache-phpfpm:7.2
- eilandert/apache-phpfpm:7.4
- eilandert/apache-phpfpm:8.0
Debian:
- eilandert/apache-phpfpm:deblatest defaults to 7.4 at this time
- eilandert/apache-phpfpm:debmulti for all php versions
- eilandert/apache-phpfpm:deb5.6
- eilandert/apache-phpfpm:deb7.2
- eilandert/apache-phpfpm:deb7.4
- eilandert/apache-phpfpm:deb8.0


TODO

I am open for suggestions..
