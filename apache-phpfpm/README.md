# Apache + PHP-FPM

An Ubuntu-rolling docker with PHP packages from [Ondrej](https://launchpad.net/~ondrej/+archive/ubuntu/php)

This docker can be found on [Github](https://github.com/eilandert/dockerized/tree/master/apache-phpfpm) and [Dockerhub](https://hub.docker.com/r/eilandert/apache-phpfpm)

Complete Apache packages are on my [Launchpad](https://launchpad.net/~eilander/+archive/ubuntu/apache2)

Features of apache:

- Updated rebuild and backport of the Ubuntu-20.10 Groovy Apache2 Package with OpenSSL 1.1.1h
- Compiled with -O3 -flto to squeeze some extra % performance.
- Linked all builds against OpenSSL 1.1.1h so there is ALPN and TLS1.3 support

A docker I created for serving wordpress, opencart and magento behind a reverse nginx proxy, but all functionality is there so you should be able to use it any way you want<BR>

FEATURES:

- Nullmailer for easy mailing from within e.g. wordpress
- Most php-modules are included.
- Daily reload of configs when mod_ssl is enabled (for reloading e.g. letsencrypt certificates)
- Automatic population of /etc/apache2 /etc/php and /etc/nullmailer if configs are not found (e.g. first run on mounted empty dir)
- pre-enabled modules during build: proxy_fcgi setenvif rewrite expires headers remoteip

ENVIRONMENT:

- use CACHE=yes to enable apache caching
- use TZ=Europe/Amsterdam (for example) to set timezone
- variables A2ENMOD A2DISMOD A2ENCONF A2DISCONF (changes are persistent if you mount /etc/apache2)
- use MODE=FPM for using php-fpm (default)
- use MODE=MOD for using mod_php instead of php-fpm. Apache2 will be set to mpm_prefork.
- use MODE=MULTI to enable running multiple php-fpm versions. You'll need to pull the multi-tag docker
- in multimode set PHP56=YES PHP72=YES PHP74=YES PHP80=YES to enable specific versions.
- in multimode you have to create the handler per vhost manually, examples in apache2/conf-available/php\*-fpm.conf

See [docker-compose.yml](https://github.com/eilandert/dockerized/blob/master/apache-phpfpm/docker-compose.yml) for examples.

TAGS:

- eilandert/apache-phpfpm:latest defaults to 7.4 at this time
- eilandert/apache-phpfpm:multi for all php versions
- eilandert/apache-phpfpm:5.6
- eilandert/apache-phpfpm:7.2
- eilandert/apache-phpfpm:7.4
- eilandert/apache-phpfpm:8.0

TODO

I am open for suggestions..
