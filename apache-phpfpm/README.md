
Apache + PHP-FPM (packages from https://launchpad.net/~ondrej)

A docker I created for serving wordpress behind a proxy, but I guess you could do anything with it. 

It includes nullmailer for easy mailing from within e.g. wordpress

Both php-mysql and php-pgsql and most php-modules are included.

Bind /etc/php, /etc/apache2 and /etc/nullmailer to a local dir, it will be populated on first run. See docker-compose.yml on my github for examples.

I am open for suggestions.

Tags:
eilandert/apache-phpfpm:7.2
eilandert/apache-phpfpm:7.4
eilandert/apache-phpfpm:8.0

eilandert/apache-phpfpm:latest -> 7.4
