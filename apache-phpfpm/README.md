# Apache + PHP-FPM 

###### An Ubuntu-latest docker with packages from Ondrej ([Apache](https://launchpad.net/~ondrej/+archive/ubuntu/apache2) and [PHP](https://launchpad.net/~ondrej/+archive/ubuntu/php))


A docker I created for serving wordpress behind a reverse proxy, but all functionality is there<BR>


###### Features:

* Nullmailer for easy mailing from within e.g. wordpress
* Most php-modules are included.
* Daily reload of configs when mod_ssl is enabled (for reloading e.g. letsencrypt certificates)
* Automatic population of /etc/apache2 /etc/php and /etc/nullmailer if configs are not found (e.g. first run on mounted empty dir)
* ENVIRONMENT: use MODE=mod for using mod_php instead of php-fpm. Apache2 will be set to mpm_prefork.
* ENVIRONMENT: use CACHE=yes to enable caching
* ENVIRONMENT: use TZ=Europe/Amsterdam (for example) to set timezone 
* ENVIRONMENT: A2ENMOD A2DISMOD A2ENCONF A2DISCONF (changes are persistent if you mount /etc/apache2)
* ENVIRONMENT: pre-enabled modules during build: proxy_fcgi setenvif rewrite expires headers remoteip

See [docker-compose.yml](https://github.com/eilandert/dockerized/blob/master/apache-phpfpm/docker-compose.yml) for examples.

###### Tags:

eilandert/apache-phpfpm:5.6<BR>
eilandert/apache-phpfpm:7.2<BR>
eilandert/apache-phpfpm:7.4<BR>
eilandert/apache-phpfpm:8.0<BR>

eilandert/apache-phpfpm:latest defaults to 7.4 at this time until my wordpress environment is 8.0 ready.

###### TODO

I am open for suggestions..
