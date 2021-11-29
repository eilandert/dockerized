Dockerized NGINX+MODSECURITY3+GOOGLE PAGESPEED
-
This docker can be found on  **[Github](https://github.com/eilandert/dockerized/tree/master/nginx-proxy-modsecurity-pagespeed)**  and **[Dockerhub](https://hub.docker.com/r/eilandert/nginx-modsecurity3-pagespeed)** 

**Complete packages and description are on my  [PPA](http://deb.paranoid.nl/pages/nginx.html)**

PHP packages are from  **[Ondrejs excellent PPA](https://launchpad.net/~ondrej/+archive/ubuntu/php)**

All php containers include nullmailer and composer.

Tags: 

Debian:
-   eilandert/nginx-modsecurity3-pagespeed:deb-latest (without php, nullmailer or composer)
-   eilandert/nginx-modsecurity3-pagespeed:deb-multi (with all versions of php)
-   eilandert/nginx-modsecurity3-pagespeed:deb-php5.6
-   eilandert/nginx-modsecurity3-pagespeed:deb-php7.2
-   eilandert/nginx-modsecurity3-pagespeed:deb-php7.4
-   eilandert/nginx-modsecurity3-pagespeed:deb-php8.0
-   eilandert/nginx-modsecurity3-pagespeed:deb-php8.1)

Ubuntu:
-   eilandert/nginx-modsecurity3-pagespeed:latest (without php, nullmailer or composer)
-   eilandert/nginx-modsecurity3-pagespeed:multi (with all versions of php, nullmailer and composer)
-   eilandert/nginx-modsecurity3-pagespeed:php5.6 
-   eilandert/nginx-modsecurity3-pagespeed:php7.2 
-   eilandert/nginx-modsecurity3-pagespeed:php7.4 
-   eilandert/nginx-modsecurity3-pagespeed:php8.0
-   eilandert/nginx-modsecurity3-pagespeed:php8.1

For the tag with multi, you can enable different versions with environmentvariable PHP56=YES PHP72=YES PHP74=YES and PHP80=YES 
Socket will be made in /run/php/php7.4-fpm.sock or whatever version you enabled. 

Bind /etc/nginx and /etc/modsecurity (for php, /etc/nullmailer and /etc/php) to an empty local directory and it will be populated on first run with default configs.

See my github for an example of  **[docker-compose.yml](https://github.com/eilandert/dockerized/blob/master/nginx-proxy-modsecurity-pagespeed/docker-compose.yml)**

Environment variables:

	- TZ=Europe/Amsterdam
        - PHP56=YES (if the multi-php docker is pulled)
        - PHP74=YES (if the multi-php docker is pulled)
        - PHP74=YES (if the multi-php docker is pulled)
        - PHP80=YES (if the multi-php docker is pulled)
        - PHP80=YES (if the multi-php docker is pulled)
 
        - NGX_MODULES=mod-security-headers,mod-http-fancyindex

        At the time of writing you can enable the following modules:
          mod-brotli
          mod-http-auth-pam
          mod-http-auth-spnego
          mod-http-cache-purge
          mod-http-dav-ext
          mod-http-doh
          mod-http-echo
          mod-http-fancyindex
          mod-http-geoip
          mod-http-geoip2
          mod-http-headers-more-filter
          mod-http-image-filter
          mod-http-lua
          mod-http-ndk
          mod-http-njs
          mod-http-perl
          mod-http-subs-filter
          mod-http-uploadprogress
          mod-http-upstream-fair
          mod-http-xslt-filter
          mod-mail
          mod-modsecurity
          mod-nchan
          mod-pagespeed
          mod-rtmp
          mod-security-headers
          mod-ssl-ct
          mod-stream-geoip
          mod-stream-geoip2
          mod-stream
          mod-vts

I am open to suggestions!
