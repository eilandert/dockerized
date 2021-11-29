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

Environmentvariables:
	- TZ=Europe/Amsterdam
        - PHP56=YES (if the multi-php docker is pulled)
        - PHP74=YES (if the multi-php docker is pulled)
        - PHP74=YES (if the multi-php docker is pulled)
        - PHP80=YES (if the multi-php docker is pulled)
        - PHP80=YES (if the multi-php docker is pulled)
 
        - NGX_MODULES="mod-security-headers.conf, mod-http-fancyindex.conf"

        At the time of writing you can enable the following modules:
          mod-brotli.conf
          mod-http-auth-pam.conf
          mod-http-auth-spnego.conf
          mod-http-cache-purge.conf
          mod-http-dav-ext.conf
          mod-http-doh.conf
          mod-http-echo.conf
          mod-http-fancyindex.conf
          mod-http-geoip.conf
          mod-http-geoip2.conf
          mod-http-headers-more-filter.conf
          mod-http-image-filter.conf
          mod-http-lua.conf
          mod-http-ndk.conf
          mod-http-njs.conf
          mod-http-perl.conf
          mod-http-subs-filter.conf
          mod-http-uploadprogress.conf
          mod-http-upstream-fair.conf
          mod-http-xslt-filter.conf
          mod-mail.conf
          mod-modsecurity.conf
          mod-nchan.conf
          mod-pagespeed.conf
          mod-rtmp.conf
          mod-security-headers.conf
          mod-ssl-ct.conf
          mod-stream-geoip.conf
          mod-stream-geoip2.conf
          mod-stream.conf
          mod-vts.conf


I am open to suggestions!
